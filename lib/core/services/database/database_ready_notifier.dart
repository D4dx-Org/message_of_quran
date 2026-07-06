import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

enum DbInitStatus { loading, ready, failed }

/// Tracks [DatabaseHelper.initializeServices] lifecycle so the web UI can
/// render immediately and let only DB-dependent widgets wait/retry, instead
/// of gating the whole app behind the DB load.
class DatabaseReadyNotifier extends ChangeNotifier {
  DatabaseReadyNotifier();

  factory DatabaseReadyNotifier.ready() {
    final notifier = DatabaseReadyNotifier();
    notifier._status = DbInitStatus.ready;
    notifier._completer.complete();
    return notifier;
  }

  DbInitStatus _status = DbInitStatus.loading;
  DbInitStatus get status => _status;

  Object? error;

  Completer<void> _completer = Completer<void>();
  Future<void> get whenReady => _completer.future;

  void start() {
    _status = DbInitStatus.loading;
    error = null;
    notifyListeners();
    unawaited(_run());
  }

  void retry() {
    if (_status != DbInitStatus.failed) return;
    _completer = Completer<void>();
    start();
  }

  Future<void> _run() async {
    try {
      await DatabaseHelper.initializeServices();
      _status = DbInitStatus.ready;
      if (!_completer.isCompleted) _completer.complete();
      notifyListeners();
    } catch (e) {
      _status = DbInitStatus.failed;
      error = e;
      if (!_completer.isCompleted) _completer.completeError(e);
      notifyListeners();
    }
  }
}
