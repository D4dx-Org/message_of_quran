import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:the_message_of_the_quran/core/services/quran_audio_skip_router.dart';

/// A shared [BaseAudioHandler] that wraps a single [AudioPlayer] instance.
/// Both surah audio and mushaf audio go through this handler so that:
/// 1. A media notification with play/pause/stop controls is shown.
/// 2. Lock-screen and headphone controls work.
/// 3. Audio continues playing when the app is backgrounded.
class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  late AudioPlayer _player;
  AudioPlayer get player => _player;
  final QuranAudioSkipRouter _skipRouter = QuranAudioSkipRouter();

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _positionSub;

  QuranAudioHandler() {
    _player = AudioPlayer(
      androidApplyAudioAttributes: false,
      handleAudioSessionActivation: false,
    );
    _init();
  }

  Future<void> _init() async {
    await _configureAudioSession();
    _subscribeToPlayer();
  }

  Future<void> _configureAudioSession() async {
    if (kIsWeb) {
      return;
    }

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
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
      debugPrint('QuranAudioHandler: audio session config failed — $e');
    }
  }

  /// Cancels old subscriptions and subscribes to the current player's streams.
  void _subscribeToPlayer() {
    _playerStateSub?.cancel();
    _indexSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();

    _playerStateSub = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

      // Map just_audio ProcessingState → audio_service AudioProcessingState
      final audioProcessingState = switch (processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: audioProcessingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });

    _indexSub = _player.currentIndexStream.listen((index) {
      // The mediaItem is set externally by AudioProvider / MushafReaderProvider
      // when the track changes.  Nothing to do here.
    });

    _durationSub = _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });

    _positionSub = _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });
  }

  /// Replaces the underlying player after a catastrophic failure.
  /// Used by the fallback logic in providers.
  AudioPlayer recreatePlayer() {
    _player = AudioPlayer(
      androidApplyAudioAttributes: false,
      handleAudioSessionActivation: false,
    );
    _subscribeToPlayer();
    return _player;
  }

  void setSkipDelegate({
    required Object owner,
    AudioSkipCallback? onNext,
    AudioSkipCallback? onPrevious,
  }) {
    _skipRouter.setDelegate(
      owner: owner,
      onNext: onNext,
      onPrevious: onPrevious,
    );
  }

  void clearSkipDelegate({Object? owner}) {
    _skipRouter.clearDelegate(owner: owner);
  }

  // ─── BaseAudioHandler overrides ────────────────────────────────────────

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (await _skipRouter.skipToNext()) {
      return;
    }
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (await _skipRouter.skipToPrevious()) {
      return;
    }
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    playbackState.add(playbackState.value.copyWith(
      speed: speed,
    ));
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await _player.dispose();
  }
}

/// Singleton-style access to the initialized handler.
/// Set during app startup in main.dart.
QuranAudioHandler? audioHandler;
