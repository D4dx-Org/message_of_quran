import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';

import 'font_download_service.dart';
import 'mushaf_install_state.dart';

const int _kMushafDownloadNotificationId = 30;
const String mushafDownloadChannelKey = 'mushaf_download';

enum MushafDownloadStatus { idle, downloading, completed, error }

/// Singleton that runs the Mushaf font-pack download in the background.
class MushafDownloadManager extends ChangeNotifier {
  MushafDownloadManager._();

  static final MushafDownloadManager instance = MushafDownloadManager._();

  MushafDownloadStatus _status = MushafDownloadStatus.idle;
  double _progress = 0;
  String? _error;

  MushafDownloadStatus get status => _status;
  double get progress => _progress;
  String? get error => _error;
  bool get isDownloading => _status == MushafDownloadStatus.downloading;
  bool get isDone => _status == MushafDownloadStatus.completed;
  bool get isDownloadSupported => FontDownloadService.isDownloadSupported;

  Future<void> startDownload() async {
    if (_status == MushafDownloadStatus.downloading) return;

    if (!isDownloadSupported) {
      _progress = 0;
      _error = FontDownloadService.unsupportedPlatformMessage;
      _status = MushafDownloadStatus.error;
      notifyListeners();
      _dismissNotification();
      return;
    }

    _status = MushafDownloadStatus.downloading;
    _progress = 0;
    _error = null;
    notifyListeners();

    _showProgressNotification(0);

    try {
      await for (final p in FontDownloadService.instance.downloadFontPack()) {
        _progress = p;
        notifyListeners();
        final percent = (p * 100).round();
        _showProgressNotification(percent);
      }

      _status = MushafDownloadStatus.completed;
      notifyListeners();
      _showCompletedNotification();
    } catch (e) {
      log('MushafDownloadManager: error — $e');
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = MushafDownloadStatus.error;
      notifyListeners();
      _dismissNotification();
    }
  }

  void cancel() {
    FontDownloadService.instance.cancel();
    _status = MushafDownloadStatus.idle;
    _progress = 0;
    notifyListeners();
    _dismissNotification();
  }

  void reset() {
    _status = MushafDownloadStatus.idle;
    _progress = 0;
    _error = null;
    notifyListeners();
  }

  Future<void> syncWithPersistedState() async {
    final installed = await MushafInstallState.instance.isFullFontsInstalled;
    if (installed && _status != MushafDownloadStatus.completed) {
      _status = MushafDownloadStatus.completed;
      notifyListeners();
    }
  }

  void _showProgressNotification(int percent) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _kMushafDownloadNotificationId,
        channelKey: mushafDownloadChannelKey,
        title: 'Downloading Mushaf',
        body: 'Mushaf font pack — $percent%',
        notificationLayout: NotificationLayout.ProgressBar,
        progress: percent.toDouble(),
        locked: true,
        autoDismissible: false,
        category: NotificationCategory.Progress,
      ),
    );
  }

  void _showCompletedNotification() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _kMushafDownloadNotificationId,
        channelKey: mushafDownloadChannelKey,
        title: 'Mushaf Download Complete',
        body: 'The Mushaf font pack has been installed successfully.',
        notificationLayout: NotificationLayout.Default,
        autoDismissible: true,
      ),
    );
  }

  void _dismissNotification() {
    try {
      AwesomeNotifications()
          .cancel(_kMushafDownloadNotificationId);
    } catch (_) {}
  }
}
