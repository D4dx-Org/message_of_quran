import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:just_audio/just_audio.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/services/audio_handler.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_audio_skip.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class AudioProvider extends ChangeNotifier {
  final QuranAudioHandler _handler;
  AudioPlayer get _player => _handler.player;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _indexSub;
  bool _isDisposed = false;

  AudioProvider(this._handler);

  int _playGeneration = 0;
  SurahProvider? _surahProvider;
  PlaySettingsProvider? _playSettingsProvider;
  bool _isProgrammaticSurahTransition = false;

  int? _currentSurahNumber;
  int? _currentAyahId;       // first ayah of block (ayaStart)
  int? _playingAyahId;       // individual ayah currently being played
  int? _currentTranslationIndex;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isLoading = false;
  String? _pendingPlaybackErrorMessage;

  int? get currentSurahNumber => _currentSurahNumber;
  int? get currentAyahId => _currentAyahId;
  /// The individual ayah number currently being output (within the block).
  int? get playingAyahId => _playingAyahId;
  int? get currentTranslationIndex => _currentTranslationIndex;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isLoading => _isLoading;
  bool get isActive => _isPlaying || _isPaused || _isLoading;
  bool get isProgrammaticSurahTransition => _isProgrammaticSurahTransition;

  String? consumePendingPlaybackError() {
    final message = _pendingPlaybackErrorMessage;
    _pendingPlaybackErrorMessage = null;
    return message;
  }

  /// Called when all ayahs in the block finish.
  /// Receives (surahNumber, completedTranslationIndex).
  void Function(int surahNumber, int translationIndex)? onAyahComplete;

  void attachDependencies({
    required SurahProvider surahProvider,
    required PlaySettingsProvider playSettings,
  }) {
    _surahProvider = surahProvider;
    _playSettingsProvider = playSettings;
  }

  void setProgrammaticSurahTransition(bool value) {
    _isProgrammaticSurahTransition = value;
  }

  static String buildUrl(ReciterInfo reciter, int surahNumber, int ayahId) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahId.toString().padLeft(3, '0');
    return '${ApiConstants.everyAyahAudioBaseUrl}/${reciter.folderName}/$surah$ayah.mp3';
  }

  void _queuePlaybackError(String message, {bool notify = true}) {
    _pendingPlaybackErrorMessage = message;
    if (notify) {
      notifyListeners();
    }
  }

  /// Updates the media notification with current track info.
  void _updateMediaItem({
    required int surahNumber,
    required int ayahId,
    String? reciterName,
  }) {
    _handler.mediaItem.add(MediaItem(
      id: 'surah_${surahNumber}_ayah_$ayahId',
      album: 'Quran Asad Malayalam',
      title: 'Surah $surahNumber - Ayah $ayahId',
      artist: reciterName ?? 'Quran Recitation',
    ));
  }

  Future<void> playAyah({
    required int surahNumber,
    required int ayahId,     // ayaStart
    required int ayahEndId,  // ayaEnd  (pass == ayahId for single-ayah rows)
    required int translationIndex,
    required ReciterInfo reciter,
    double playbackSpeed = 1.0,
  }) async {
    final gen = ++_playGeneration;
    _pendingPlaybackErrorMessage = null;

    await _playerStateSub?.cancel();
    await _indexSub?.cancel();
    _playerStateSub = null;
    _indexSub = null;

    // A newer playAyah() call was made while we were awaiting above.
    if (gen != _playGeneration) return;

    _currentSurahNumber = surahNumber;
    _currentAyahId = ayahId;
    _playingAyahId = ayahId;
    _currentTranslationIndex = translationIndex;
    _isLoading = true;
    _isPlaying = false;
    _isPaused = false;
    notifyListeners();

    // Update media notification
    _handler.setSkipDelegate(
      owner: this,
      onNext: skipToNextBlock,
      onPrevious: skipToPreviousBlock,
    );
    _updateMediaItem(
      surahNumber: surahNumber,
      ayahId: ayahId,
      reciterName: reciter.name,
    );

    // Build a playlist for every individual ayah in the range.
    final count = (ayahEndId - ayahId).abs() + 1;
    final sources = List<AudioSource>.generate(count, (i) {
      final url = buildUrl(reciter, surahNumber, ayahId + i);
      log('AudioProvider: queuing $url');
      return AudioSource.uri(Uri.parse(url));
    });
    final playlist = ConcatenatingAudioSource(children: sources);
    log(
      'AudioProvider: playlist has $count track(s) – surah=$surahNumber '
      'ayah=$ayahId..$ayahEndId reciter=${reciter.folderName}',
    );

    try {
      log('AudioProvider: setting audio source…');
      await _setAudioSourceWithFallback(playlist);
      if (gen != _playGeneration) return;
      await _player.setSpeed(playbackSpeed);
      if (gen != _playGeneration) return;

      // Subscribe AFTER setAudioSource so the BehaviorSubject replays
      // "ready" state instead of stale "completed" from the previous
      // playlist.  This prevents onAyahComplete from re-firing.
      _setupStreamListeners(gen, ayahId, reciter.name);

      log('AudioProvider: calling play()');
      _player.play(); // intentionally NOT awaited
    } catch (e) {
      log('AudioProvider: playAyah ERROR – $e');
      if (gen != _playGeneration) return;
      _queuePlaybackError(
        'Unable to play ${reciter.name} right now. Try another reciter or try again later.',
        notify: false,
      );
      _isLoading = false;
      _isPlaying = false;
      _currentAyahId = null;
      _playingAyahId = null;
      _currentSurahNumber = null;
      _currentTranslationIndex = null;
      notifyListeners();
    }
  }

  void _setupStreamListeners(int gen, int baseAyahId, String reciterName) {
    // Track which individual ayah within the block is currently playing.
    _indexSub = _player.currentIndexStream.listen((idx) {
      if (gen != _playGeneration) return;
      if (idx != null) {
        final newAyah = baseAyahId + idx;
        if (_playingAyahId != newAyah) {
          _playingAyahId = newAyah;
          // Update media notification with current ayah
          if (_currentSurahNumber != null) {
            _updateMediaItem(
              surahNumber: _currentSurahNumber!,
              ayahId: newAyah,
              reciterName: reciterName,
            );
          }
          // ignore: deprecated_member_use
          SemanticsService.announce(
            'Now playing Ayah $newAyah',
            TextDirection.ltr,
          );
          notifyListeners();
        }
      }
    }, onError: (e) {
      log('AudioProvider: currentIndexStream error – $e');
    });

    // Drive UI state from playerStateStream.
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (gen != _playGeneration) return;
      final playing = state.playing;
      final proc = state.processingState;

      log('AudioProvider: playerState playing=$playing proc=$proc');

      if (proc == ProcessingState.loading || proc == ProcessingState.buffering) {
        if (!_isLoading) {
          _isLoading = true;
          _isPlaying = false;
          notifyListeners();
        }
      } else if (playing && proc == ProcessingState.ready) {
        if (!_isPlaying || _isLoading) {
          _isLoading = false;
          _isPlaying = true;
          _isPaused = false;
          notifyListeners();
        }
      } else if (!playing && proc == ProcessingState.ready) {
        if (_isPlaying || _isLoading) {
          _isLoading = false;
          _isPlaying = false;
          _isPaused = true;
          notifyListeners();
        }
      } else if (proc == ProcessingState.completed) {
        _isPlaying = false;
        _isPaused = false;
        _isLoading = false;
        // ignore: deprecated_member_use
        SemanticsService.announce('Playback finished', TextDirection.ltr);
        _playingAyahId = null;
        _currentAyahId = null;
        notifyListeners();
        final capturedSurah = _currentSurahNumber;
        final capturedIndex = _currentTranslationIndex;
        if (capturedSurah != null && capturedIndex != null) {
          Future.microtask(() {
            if (gen != _playGeneration) return;
            onAyahComplete?.call(capturedSurah, capturedIndex);
          });
        }
      }
    }, onError: (e) {
      log('AudioProvider: playerStateStream error – $e');
      if (gen != _playGeneration) return;
      _queuePlaybackError(
        'Unable to continue $reciterName audio. Try another reciter or try again later.',
        notify: false,
      );
      _isLoading = false;
      _isPlaying = false;
      _isPaused = false;
      _currentAyahId = null;
      _playingAyahId = null;
      notifyListeners();
    });
  }

  Future<void> _setAudioSourceWithFallback(AudioSource source) async {
    try {
      await _player.setAudioSource(source);
    } catch (e) {
      log('AudioProvider: setAudioSource failed – $e');

      try {
        log('AudioProvider: trying seek(0) + retry');
        await _player.seek(Duration.zero, index: 0);
        await _player.setAudioSource(source);
        return;
      } catch (e2) {
        log('AudioProvider: seek+retry failed – $e2');
      }

      // ── Fallback 2: recreate player via handler ──
      log('AudioProvider: recreating player via handler');
      await _playerStateSub?.cancel();
      await _indexSub?.cancel();
      _playerStateSub = null;
      _indexSub = null;

      final completer = Completer<void>();
      runZonedGuarded(() async {
        _handler.recreatePlayer();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await _player.setAudioSource(source);
        if (!completer.isCompleted) completer.complete();
      }, (error, stack) {
        log('AudioProvider: guarded zone caught – $error');
        if (!completer.isCompleted) completer.completeError(error, stack);
      });
      await completer.future;
    }
  }

  Future<void> stopAudio() async {
    await _playerStateSub?.cancel();
    await _indexSub?.cancel();
    _playerStateSub = null;
    _indexSub = null;
    try { await _handler.stop(); } catch (e) { debugPrint('AudioProvider: stop failed — $e'); }
    _handler.clearSkipDelegate(owner: this);
    _isPlaying = false;
    _isPaused = false;
    _isLoading = false;
    _currentAyahId = null;
    _playingAyahId = null;
    _currentSurahNumber = null;
    _currentTranslationIndex = null;
    // ignore: deprecated_member_use
    SemanticsService.announce('Audio stopped', TextDirection.ltr);
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _handler.pause();
      // ignore: deprecated_member_use
      SemanticsService.announce('Audio paused', TextDirection.ltr);
    } else if (_isPaused) {
      // ignore: deprecated_member_use
      SemanticsService.announce('Audio resumed', TextDirection.ltr);
      _handler.play(); // not awaited
    }
  }

  /// Changes playback speed on-the-fly (works while playing or paused).
  Future<void> setSpeed(double speed) async {
    try { await _handler.setSpeed(speed); } catch (e) { debugPrint('AudioProvider: setSpeed failed — $e'); }
  }

  bool isCurrentAyah(int surahNumber, int ayahId) {
    return _currentSurahNumber == surahNumber &&
        _currentAyahId == ayahId &&
        isActive;
  }

  Future<void> skipToNextBlock() async {
    await _skipWithinSurahAudio(SurahAudioSkipDirection.next);
  }

  Future<void> skipToPreviousBlock() async {
    await _skipWithinSurahAudio(SurahAudioSkipDirection.previous);
  }

  Future<void> _skipWithinSurahAudio(SurahAudioSkipDirection direction) async {
    final surahProv = _surahProvider;
    final playSettings = _playSettingsProvider;
    final currentSurahNumber = _currentSurahNumber;
    if (surahProv == null || playSettings == null || currentSurahNumber == null) {
      return;
    }

    if (surahProv.surahList.isEmpty) {
      await surahProv.getAllSurah();
    }

    final targetSurahIndex = surahProv.surahList.indexWhere(
      (surah) => surah.surahNumber == currentSurahNumber,
    );
    if (targetSurahIndex < 0) {
      return;
    }

    if (surahProv.index != targetSurahIndex || surahProv.arabicBlockList.isEmpty) {
      surahProv.assignIndex(targetSurahIndex);
      await surahProv.getAyasForCurrentSurah();
    }

    var blocks = surahProv.arabicBlockList;
    final currentBlockIndex = _resolveCurrentBlockIndex(blocks);
    if (currentBlockIndex == null) {
      return;
    }

    final hasAdjacentSurah = direction == SurahAudioSkipDirection.next
        ? targetSurahIndex < surahProv.surahList.length - 1
        : targetSurahIndex > 0;
    final target = resolveSurahAudioSkipTarget(
      currentBlockIndex: currentBlockIndex,
      blockCount: blocks.length,
      direction: direction,
      hasAdjacentSurah: hasAdjacentSurah,
    );
    if (target == null) {
      return;
    }

    var resolvedSurahIndex = targetSurahIndex;
    var resolvedBlockIndex = target.blockIndex;
    if (target.boundaryMove != SurahAudioBoundaryMove.stay) {
      resolvedSurahIndex +=
          target.boundaryMove == SurahAudioBoundaryMove.nextSurah ? 1 : -1;
      await _runProgrammaticSurahTransition(() async {
        surahProv.assignIndex(resolvedSurahIndex);
        await surahProv.getAyasForCurrentSurah();
      });
      blocks = surahProv.arabicBlockList;
      if (blocks.isEmpty) {
        return;
      }
      if (resolvedBlockIndex < 0) {
        resolvedBlockIndex = blocks.length - 1;
      }
    }

    if (resolvedBlockIndex < 0 || resolvedBlockIndex >= blocks.length) {
      return;
    }

    await _playBlock(
      surahNumber: surahProv.surahList[resolvedSurahIndex].surahNumber,
      block: blocks[resolvedBlockIndex],
      translationIndex: resolvedBlockIndex,
      playSettings: playSettings,
    );
  }

  int? _resolveCurrentBlockIndex(List<dynamic> blocks) {
    final translationIndex = _currentTranslationIndex;
    if (translationIndex != null &&
        translationIndex >= 0 &&
        translationIndex < blocks.length) {
      return translationIndex;
    }

    final playingAyah = _playingAyahId ?? _currentAyahId;
    if (playingAyah == null) {
      return null;
    }

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final start = block.verseFrom ?? 0;
      final end = block.verseTo ?? start;
      if (start <= playingAyah && playingAyah <= end) {
        return i;
      }
    }
    return null;
  }

  Future<void> _playBlock({
    required int surahNumber,
    required dynamic block,
    required int translationIndex,
    required PlaySettingsProvider playSettings,
  }) {
    final ayahStart = block.verseFrom ?? 1;
    final ayahEnd = block.verseTo ?? ayahStart;
    return playAyah(
      surahNumber: surahNumber,
      ayahId: ayahStart,
      ayahEndId: ayahEnd,
      translationIndex: translationIndex,
      reciter: playSettings.selectedReciter,
      playbackSpeed: playSettings.playbackSpeed,
    );
  }

  Future<void> _runProgrammaticSurahTransition(
    Future<void> Function() action,
  ) async {
    setProgrammaticSurahTransition(true);
    try {
      await action();
    } finally {
      setProgrammaticSurahTransition(false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _playerStateSub?.cancel();
    _indexSub?.cancel();
    _handler.clearSkipDelegate(owner: this);
    // Don't dispose the player – it's shared via the handler
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }
}
