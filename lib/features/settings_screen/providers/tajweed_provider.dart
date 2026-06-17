import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tajweed/services/tajweed_font_download_service.dart';

/// Manages the full Tajweed feature lifecycle:
/// - whether Tajweed is enabled,
/// - whether the 604-page font pack is installed,
/// - download progress / error state,
/// - delete/reset.
///
/// Uses [TajweedFontDownloadService] for the actual font download.
class TajweedProvider extends ChangeNotifier {
  static const String _enabledKey = 'isTajweedEnabled';

  bool _isDisposed = false;

  bool _enabled = false;
  bool _fontsInstalled = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadError;

  StreamSubscription<double>? _downloadSub;

  bool get enabled => _enabled;
  bool get fontsInstalled => _fontsInstalled;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get downloadError => _downloadError;

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _downloadSub?.cancel();
    super.dispose();
  }

  // Lifecycle
  TajweedProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;

    // Re-verify install state on every startup (handles reinstalls/deletes).
    _fontsInstalled = await TajweedFontDownloadService.instance.isInstalled;

    // Auto-disable if the fonts disappeared after a reinstall or delete.
    if (_enabled && !_fontsInstalled) {
      _enabled = false;
      await prefs.setBool(_enabledKey, false);
      log('TajweedProvider: fonts missing — Tajweed auto-disabled');
    }

    notifyListeners();
  }

  // Enable / Disable
  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;

    if (!value) {
      await _cancelDownloadInternal();
      _enabled = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, false);
      notifyListeners();
      return;
    }

    // Turning on: check if fonts are already installed.
    _fontsInstalled = await TajweedFontDownloadService.instance.isInstalled;
    if (_fontsInstalled) {
      _enabled = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, true);
      notifyListeners();
      return;
    }

    // Fonts not present — caller must call startDownload() after confirmation.
    notifyListeners();
  }

  // Download
  Future<void> startDownload() async {
    if (_isDownloading) return;

    _isDownloading = true;
    _downloadProgress = 0.0;
    _downloadError = null;
    notifyListeners();

    final service = TajweedFontDownloadService.instance;

    _downloadSub?.cancel();
    _downloadSub = service.downloadFontPack().listen(
      (progress) {
        _downloadProgress = progress;
        notifyListeners();
      },
      onDone: () async {
        _isDownloading = false;
        _fontsInstalled = await service.isInstalled;
        if (_fontsInstalled) {
          _enabled = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_enabledKey, true);
          log('TajweedProvider: download complete — Tajweed enabled');
        } else {
          _downloadError = 'Install verification failed. Please retry.';
          log('TajweedProvider: verification failed after download');
        }
        notifyListeners();
      },
      onError: (Object error) {
        _isDownloading = false;
        _downloadError = 'Download failed: $error';
        log('TajweedProvider: download error — $error');
        notifyListeners();
      },
    );
  }

  Future<void> _cancelDownloadInternal() async {
    _downloadSub?.cancel();
    _downloadSub = null;
    TajweedFontDownloadService.instance.cancel();
    _isDownloading = false;
    _downloadProgress = 0.0;
    _downloadError = null;
  }

  void cancelDownload() {
    unawaited(_cancelDownloadInternal().then((_) => notifyListeners()));
  }

  // Delete / Reset
  Future<void> deleteFontPack() async {
    await _cancelDownloadInternal();
    await TajweedFontDownloadService.instance.deleteFontPack();
    _fontsInstalled = false;
    _enabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
    notifyListeners();
  }

  // Retry
  Future<void> retryDownload() async {
    _downloadError = null;
    notifyListeners();
    await startDownload();
  }
}
