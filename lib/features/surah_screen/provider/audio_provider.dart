import 'dart:async';
import 'dart:developer';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:just_audio/just_audio.dart';

class AudioProvider extends ChangeNotifier {
  AudioPlayer _player = AudioPlayer(
    androidApplyAudioAttributes: false,
    handleAudioSessionActivation: false,
  );
  StreamSubscription? _playerStateSub;
  StreamSubscription? _indexSub;
  bool _isDisposed = false;

  AudioProvider() {
    _configureAudioSession();
  }

  /// Sets up an audio session suitable for music/Quran recitation so that
  /// playback continues when the screen is locked or the app is backgrounded.
  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
    } catch (e) {
      // Audio session configuration is best-effort; playback still works
      // without it on most devices.
      debugPrint('AudioProvider: audio session config failed — $e');
    }
  }

  AudioPlayer _createPlayer() => AudioPlayer(
        androidApplyAudioAttributes: false,
        handleAudioSessionActivation: false,
      );

  int _playGeneration = 0;

  int? _currentSurahNumber;
  int? _currentAyahId;       // first ayah of block (ayaStart)
  int? _playingAyahId;       // individual ayah currently being played
  int? _currentTranslationIndex;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isLoading = false;

  int? get currentSurahNumber => _currentSurahNumber;
  int? get currentAyahId => _currentAyahId;
  /// The individual ayah number currently being output (within the block).
  int? get playingAyahId => _playingAyahId;
  int? get currentTranslationIndex => _currentTranslationIndex;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isLoading => _isLoading;
  bool get isActive => _isPlaying || _isPaused || _isLoading;

  /// Called when all ayahs in the block finish.
  /// Receives (surahNumber, completedTranslationIndex).
  void Function(int surahNumber, int translationIndex)? onAyahComplete;

  static String buildUrl(String folderName, int surahNumber, int ayahId) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahId.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$folderName/$surah$ayah.mp3';
  }

  Future<void> playAyah({
    required int surahNumber,
    required int ayahId,     // ayaStart
    required int ayahEndId,  // ayaEnd  (pass == ayahId for single-ayah rows)
    required int translationIndex,
    required String reciterFolder,
    double playbackSpeed = 1.0,
  }) async {
    final gen = ++_playGeneration;

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

    // Do NOT call stop() here.  stop() transitions ExoPlayer to idle which
    // internally fires _setPlatformActive(false).  That races with the
    // _setPlatformActive(true) from setAudioSource below and causes
    // PlatformException(abort, "Loading interrupted").
    // setAudioSource() on its own correctly interrupts and replaces the
    // current source.

    // Build a playlist for every individual ayah in the range.
    final count = (ayahEndId - ayahId).abs() + 1;
    final sources = List<AudioSource>.generate(count, (i) {
      final url = buildUrl(reciterFolder, surahNumber, ayahId + i);
      log('AudioProvider: queuing $url');
      return AudioSource.uri(Uri.parse(url));
    });
    final playlist = ConcatenatingAudioSource(children: sources);
    log('AudioProvider: playlist has $count track(s) – surah=$surahNumber ayah=$ayahId..$ayahEndId reciter=$reciterFolder');

    try {
      log('AudioProvider: setting audio source…');
      await _setAudioSourceWithFallback(playlist);
      if (gen != _playGeneration) return;
      await _player.setSpeed(playbackSpeed);
      if (gen != _playGeneration) return;

      // Subscribe AFTER setAudioSource so the BehaviorSubject replays
      // "ready" state instead of stale "completed" from the previous
      // playlist.  This prevents onAyahComplete from re-firing.
      _setupStreamListeners(gen, ayahId);

      log('AudioProvider: calling play()');
      _player.play(); // intentionally NOT awaited
    } catch (e) {
      log('AudioProvider: playAyah ERROR – $e');
      // Only reset state if this is still the active generation.
      // Otherwise a newer playAyah() already set the correct state.
      if (gen != _playGeneration) return;
      _isLoading = false;
      _isPlaying = false;
      _currentAyahId = null;
      _playingAyahId = null;
      _currentSurahNumber = null;
      _currentTranslationIndex = null;
      notifyListeners();
    }
  }

  /// Sets up playerStateStream and currentIndexStream listeners for the
  /// given generation.  Called after setAudioSource so BehaviorSubject
  /// replays "ready" instead of stale "completed".
  void _setupStreamListeners(int gen, int baseAyahId) {
    // Track which individual ayah within the block is currently playing.
    _indexSub = _player.currentIndexStream.listen((idx) {
      if (gen != _playGeneration) return;
      if (idx != null) {
        final newAyah = baseAyahId + idx;
        if (_playingAyahId != newAyah) {
          _playingAyahId = newAyah;
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
          onAyahComplete?.call(capturedSurah, capturedIndex);
        }
      }
    }, onError: (e) {
      log('AudioProvider: playerStateStream error – $e');
      if (gen != _playGeneration) return;
      _isLoading = false;
      _isPlaying = false;
      _isPaused = false;
      _currentAyahId = null;
      _playingAyahId = null;
      notifyListeners();
    });
  }

  /// Tries [setAudioSource] on the existing player.  If it fails (stale
  /// ExoPlayer state), disposes the player, creates a fresh one, and retries
  /// once.  This avoids the normal dispose→new→setAudioSource race while
  /// still recovering from genuinely broken player instances.
  Future<void> _setAudioSourceWithFallback(AudioSource source) async {
    try {
      await _player.setAudioSource(source);
    } catch (e) {
      log('AudioProvider: setAudioSource failed, recreating player – $e');
      // Cancel stale subscriptions before recreating.
      await _playerStateSub?.cancel();
      await _indexSub?.cancel();
      _playerStateSub = null;
      _indexSub = null;
      try { await _player.dispose(); } catch (_) {}
      _player = _createPlayer();
      // Small delay to let the native side fully release resources.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await _player.setAudioSource(source);
    }
  }

  Future<void> stopAudio() async {
    await _playerStateSub?.cancel();
    await _indexSub?.cancel();
    _playerStateSub = null;
    _indexSub = null;
    try { await _player.stop(); } catch (e) { debugPrint('AudioProvider: stop failed — $e'); }
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
      await _player.pause();
      // ignore: deprecated_member_use
      SemanticsService.announce('Audio paused', TextDirection.ltr);
    } else if (_isPaused) {
      // ignore: deprecated_member_use
      SemanticsService.announce('Audio resumed', TextDirection.ltr);
      _player.play(); // not awaited
    }
  }

  /// Changes playback speed on-the-fly (works while playing or paused).
  Future<void> setSpeed(double speed) async {
    try { await _player.setSpeed(speed); } catch (e) { debugPrint('AudioProvider: setSpeed failed — $e'); }
  }

  bool isCurrentAyah(int surahNumber, int ayahId) {
    return _currentSurahNumber == surahNumber &&
        _currentAyahId == ayahId &&
        isActive;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _playerStateSub?.cancel();
    _indexSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }
}
