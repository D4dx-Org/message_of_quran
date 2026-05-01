import 'package:flutter/foundation.dart';

import '../services/font_download_service.dart';

/// Manages font-pack download state for the Mushaf reader.
class FontDownloadProvider extends ChangeNotifier {
  double? _progress;
  String? _error;
  bool _isDownloading = false;
  bool _isDone = false;
  bool _isDisposed = false;

  double? get progress => _progress;
  String? get error => _error;
  bool get isDownloading => _isDownloading;
  bool get isDone => _isDone;

  Future<void> start() async {
    if (_isDownloading) return;
    _isDownloading = true;
    _isDone = false;
    _error = null;
    _progress = 0;
    notifyListeners();

    try {
      await for (final p in FontDownloadService.instance.downloadFontPack()) {
        if (_isDisposed) return;
        _progress = p;
        notifyListeners();
      }
      if (_isDisposed) return;
      _isDownloading = false;
      _isDone = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isDownloading = false;
      _progress = null;
      notifyListeners();
    }
  }

  void cancel() {
    FontDownloadService.instance.cancel();
    _isDownloading = false;
    notifyListeners();
  }

  void reset() {
    _progress = null;
    _error = null;
    _isDownloading = false;
    _isDone = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
