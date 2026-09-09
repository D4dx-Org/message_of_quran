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
      await session.configure(
        const AudioSessionConfiguration(
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
        ),
      );
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

      // Map just_audio ProcessingState → audio_service AudioProcessingState.
      // just_audio is idle whenever no source is loaded, which includes the
      // gap while a newly tapped ayah's source is being set. Reporting that
      // as idle tells audio_service the session stopped: it tears the
      // notification down and, worse, both it and the Android service then
      // think they are already idle, so the *real* stop that follows is a
      // no-op and its notification is left stranded. Only a stop we asked for
      // is idle; an unasked-for one means a source is on its way.
      final audioProcessingState = switch (processingState) {
        ProcessingState.idle => _stopRequested
            ? AudioProcessingState.idle
            : AudioProcessingState.loading,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };

      // Idle means stopped: hand audio_service a bare state with no controls
      // so it tears the notification down instead of re-posting one. Without
      // this the listener keeps pushing a full control set after stop() and
      // the notification comes back with no media item behind it, which
      // Android renders as the bare "<app> is running" row.
      if (audioProcessingState == AudioProcessingState.idle) {
        playbackState.add(
          playbackState.value.copyWith(
            controls: const [],
            systemActions: const {},
            processingState: AudioProcessingState.idle,
            playing: false,
            updatePosition: Duration.zero,
            bufferedPosition: Duration.zero,
          ),
        );
        return;
      }

      playbackState.add(
        playbackState.value.copyWith(
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
        ),
      );
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
      // A stopped player still emits a final position; pushing it would
      // revive the notification we just dismissed.
      if (playbackState.value.processingState == AudioProcessingState.idle) {
        return;
      }
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
  }

  /// Replaces the underlying player after a catastrophic failure.
  /// Used by the fallback logic in providers.
  /// Whether the idle the player is about to report was asked for. See the
  /// mapping in [_subscribeToPlayer].
  bool _stopRequested = false;

  AudioPlayer recreatePlayer() {
    _stopRequested = false;
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
    _stopRequested = false;
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;
    await _player.stop();
    // The media item is deliberately left alone. Clearing it here did nothing
    // for the notification anyway -- audio_service drops a null media item
    // before it reaches either platform -- and what actually ends the
    // notification is the idle state below. The next play sets a fresh item.

    // Both halves of audio_service only tear the notification down when idle
    // *follows* a non-idle state. Pausing drops the service out of the
    // foreground, and a service that Android then restarts begins life
    // already idle -- so a lone idle here is a no-op and the notification is
    // stranded with nothing left to remove it. Announce a live state first so
    // there is always a transition to make. The pause is what makes it count:
    // audio_service reads its stream with `await for`, which drops whatever
    // arrives while it is awaiting the platform, and back-to-back events lose
    // one of the pair.
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.ready,
        playing: false,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [],
        systemActions: const {},
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
      ),
    );
    await super.stop();
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
    playbackState.add(playbackState.value.copyWith(speed: speed));
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
