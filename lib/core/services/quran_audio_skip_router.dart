typedef AudioSkipCallback = Future<void> Function();

class QuranAudioSkipRouter {
  Object? _owner;
  AudioSkipCallback? _onNext;
  AudioSkipCallback? _onPrevious;

  void setDelegate({
    required Object owner,
    AudioSkipCallback? onNext,
    AudioSkipCallback? onPrevious,
  }) {
    _owner = owner;
    _onNext = onNext;
    _onPrevious = onPrevious;
  }

  void clearDelegate({Object? owner}) {
    if (owner != null && !identical(owner, _owner)) {
      return;
    }
    _owner = null;
    _onNext = null;
    _onPrevious = null;
  }

  Future<bool> skipToNext() async {
    final callback = _onNext;
    if (callback == null) return false;
    await callback();
    return true;
  }

  Future<bool> skipToPrevious() async {
    final callback = _onPrevious;
    if (callback == null) return false;
    await callback();
    return true;
  }
}