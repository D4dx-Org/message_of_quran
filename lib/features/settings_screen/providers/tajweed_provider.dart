import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TajweedProvider extends ChangeNotifier {
  static const _enabledKey = 'tajweed_enabled';
  static const _downloadCompleteKey = 'tajweed_download_complete';
  static const _zipUrl =
      'https://d4dx-storage.blr1.cdn.digitaloceanspaces.com/thafheem-zip/tajweed_words.zip';
  static const _maxRetries = 3;

  bool _enabled = false;
  bool _isDownloading = false;
  bool _downloadPaused = false;
  double _downloadProgress = 0.0;
  bool _downloadComplete = false;
  bool _isExtracting = false;
  double _extractProgress = 0.0;
  int _extractFilesDone = 0;
  int _extractTotalFiles = 0;
  String? _downloadError;
  int _currentGeneration = 0;
  http.Client? _httpClient;
  Isolate? _extractIsolate;
  Completer<void>? _extractCompleter;
  ReceivePort? _extractProgressPort;
  ReceivePort? _extractErrorPort;
  ReceivePort? _extractExitPort;
  StreamSubscription<dynamic>? _extractProgressSubscription;
  StreamSubscription<dynamic>? _extractErrorSubscription;
  StreamSubscription<dynamic>? _extractExitSubscription;

  bool get enabled => _enabled;
  bool get isDownloading => _isDownloading;
  bool get isDownloadPaused => _downloadPaused;
  double get downloadProgress => _downloadProgress;
  bool get downloadComplete => _downloadComplete;
  bool get isExtracting => _isExtracting;
  double get extractProgress => _extractProgress;
  int get extractFilesDone => _extractFilesDone;
  int get extractTotalFiles => _extractTotalFiles;
  String? get downloadError => _downloadError;

  // ── Static helpers for resolving local image paths ──────────────────

  static String? _cachedImagesDir;

  /// Returns the directory where extracted tajweed images are stored.
  static Future<String> get imagesDirPath async {
    if (_cachedImagesDir != null) return _cachedImagesDir!;
    final docs = await getApplicationDocumentsDirectory();
    _cachedImagesDir = '${docs.path}/tajweed_images';
    return _cachedImagesDir!;
  }

  /// Derives the local file path for a given image URL.
  /// URL pattern: .../tajweed/{surah}/{ayah}/{wordpos}.png
  /// Local path:  {baseDir}/{surah}/{ayah}/{wordpos}.png
  static String localPathFor(String baseDir, String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final segments = uri.pathSegments;
    // Find the 'tajweed' segment and take everything after it.
    final idx = segments.indexOf('tajweed');
    if (idx >= 0 && idx + 1 < segments.length) {
      return '$baseDir/${segments.sublist(idx + 1).join('/')}';
    }
    // Fallback: use the last 3 segments (surah/ayah/wordpos.png).
    final tail = segments.length >= 3
        ? segments.sublist(segments.length - 3).join('/')
        : segments.last;
    return '$baseDir/$tail';
  }

  // ── Lifecycle ───────────────────────────────────────────────────────

  TajweedProvider() {
    _load();
  }

  @override
  void dispose() {
    _currentGeneration++;
    _httpClient?.close();
    _httpClient = null;
    _stopExtraction();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _downloadComplete = prefs.getBool(_downloadCompleteKey) ?? false;
    notifyListeners();

    if (_enabled && !_downloadComplete) {
      unawaited(_startDownload());
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;

    if (!value) {
      _currentGeneration++;
      _httpClient?.close();
      _httpClient = null;
      _stopExtraction();
      _isDownloading = false;
      _isExtracting = false;
      _downloadPaused = false;
      _downloadProgress = 0.0;
      _downloadError = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    notifyListeners();

    if (!_downloadComplete) {
      unawaited(_startDownload());
    }
  }

  Future<void> retryDownload() async {
    if (_isDownloading) return;
    _downloadPaused = false;
    _downloadError = null;
    notifyListeners();
    unawaited(_startDownload());
  }

  void pauseDownload() {
    if (!_isDownloading) return;
    _currentGeneration++;
    _httpClient?.close();
    _httpClient = null;
    _isDownloading = false;
    _downloadPaused = true;
    notifyListeners();
  }

  Future<void> resumeDownload() async {
    if (_isDownloading || !_enabled || _downloadComplete) return;
    _downloadPaused = false;
    _downloadError = null;
    notifyListeners();
    unawaited(_startDownload());
  }

  // ── Download: single ZIP → extract ─────────────────────────────────

  Future<void> _startDownload() async {
    if (!_enabled) return;
    final myGen = ++_currentGeneration;

    _isDownloading = true;
    _isExtracting = false;
    _downloadPaused = false;
    _downloadProgress = 0.0;
    _resetExtractionProgress();
    _downloadError = null;
    notifyListeners();

    try {
      final baseDir = await imagesDirPath;
      final imagesDir = Directory(baseDir);
      final docs = await getApplicationDocumentsDirectory();
      final tempZip = File('${docs.path}/tajweed_temp.zip');

      // ── Step 1: Download ZIP with progress (0 → 1.0) ────────────
      await _downloadZipWithRetry(tempZip, myGen);
      if (_currentGeneration != myGen) return;

      // ── Step 2: Extract ────────────────────────────────────────────
      _downloadProgress = 1.0;
      _isDownloading = false;
      _isExtracting = true;
      notifyListeners();
      await Future.delayed(Duration.zero);

      await imagesDir.create(recursive: true);
      await _extractZipInIsolate(tempZip.path, baseDir, myGen);
      if (_currentGeneration != myGen) return;

      // Clean up temp ZIP.
      if (await tempZip.exists()) await tempZip.delete();

      // ── Step 3: Verify ────────────────────────────────────────────
      final ok = await _verify(baseDir);
      if (!ok) {
        throw Exception('Extraction verification failed. Please retry.');
      }

      _isExtracting = false;
      _extractProgress = 1.0;
      _extractFilesDone = _extractTotalFiles;
      _downloadComplete = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_downloadCompleteKey, true);
      notifyListeners();
    } catch (e) {
      if (_currentGeneration != myGen) return;
      log('TajweedDownload: ERROR — $e');
      _isDownloading = false;
      _isExtracting = false;
      _downloadError = 'Download failed. Tap to retry.';
      notifyListeners();
    }
  }

  void _resetExtractionProgress() {
    _extractProgress = 0.0;
    _extractFilesDone = 0;
    _extractTotalFiles = 0;
  }

  void _completeExtraction([Object? error, StackTrace? stackTrace]) {
    final completer = _extractCompleter;
    _extractCompleter = null;
    if (completer == null || completer.isCompleted) return;
    if (error != null) {
      completer.completeError(error, stackTrace);
      return;
    }
    completer.complete();
  }

  void _disposeExtractionResources() {
    _extractProgressSubscription?.cancel();
    _extractProgressSubscription = null;
    _extractErrorSubscription?.cancel();
    _extractErrorSubscription = null;
    _extractExitSubscription?.cancel();
    _extractExitSubscription = null;
    _extractProgressPort?.close();
    _extractProgressPort = null;
    _extractErrorPort?.close();
    _extractErrorPort = null;
    _extractExitPort?.close();
    _extractExitPort = null;
    _extractIsolate = null;
  }

  void _stopExtraction() {
    _extractIsolate?.kill(priority: Isolate.immediate);
    _disposeExtractionResources();
    _completeExtraction();
    _resetExtractionProgress();
  }

  Future<void> _extractZipInIsolate(
    String zipPath,
    String outDir,
    int myGen,
  ) async {
    _disposeExtractionResources();

    final progressPort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final completer = Completer<void>();

    _extractProgressPort = progressPort;
    _extractErrorPort = errorPort;
    _extractExitPort = exitPort;
    _extractCompleter = completer;

    void finish([Object? error, StackTrace? stackTrace]) {
      _completeExtraction(error, stackTrace);
      _disposeExtractionResources();
    }

    _extractProgressSubscription = progressPort.listen((message) {
      if (message is! Map) return;
      if (_currentGeneration != myGen) return;

      final type = message['type'];
      if (type == 'count') {
        _extractTotalFiles = message['total'] as int? ?? 0;
        notifyListeners();
        return;
      }

      if (type == 'progress') {
        _extractFilesDone = message['done'] as int? ?? 0;
        if (_extractTotalFiles > 0) {
          _extractProgress = _extractFilesDone / _extractTotalFiles;
        }
        notifyListeners();
        return;
      }

      if (type == 'done') {
        _extractFilesDone = _extractTotalFiles;
        _extractProgress = _extractTotalFiles == 0 ? 0.0 : 1.0;
        notifyListeners();
        finish();
        return;
      }

      if (type == 'error') {
        finish(Exception(message['message'] ?? 'Tajweed extraction failed.'));
      }
    });

    _extractErrorSubscription = errorPort.listen((dynamic errorData) {
      final Object error;
      StackTrace? stackTrace;

      if (errorData is List && errorData.isNotEmpty) {
        error = Exception('${errorData.first}');
        if (errorData.length > 1 && errorData[1] is String) {
          stackTrace = StackTrace.fromString(errorData[1] as String);
        }
      } else {
        error = Exception('$errorData');
      }

      finish(error, stackTrace);
    });

    _extractExitSubscription = exitPort.listen((_) {
      if (_extractCompleter == null) return;
      if (_currentGeneration != myGen) {
        finish();
        return;
      }
      finish(Exception('Tajweed extraction ended unexpectedly.'));
    });

    _extractIsolate = await Isolate.spawn<Map<String, Object?>>(
      _extractZipEntryPoint,
      {
        'zipPath': zipPath,
        'outDir': outDir,
        'sendPort': progressPort.sendPort,
      },
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
      errorsAreFatal: true,
    );

    await completer.future;
  }

  Future<void> _downloadZipWithRetry(File tempZip, int myGen) async {
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await _downloadZip(tempZip, myGen);
        return;
      } on Exception catch (e) {
        if (_currentGeneration != myGen) return;
        if (attempt >= _maxRetries) rethrow;
        log('TajweedDownload: attempt $attempt failed – $e, retrying…');
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }

  Future<void> _downloadZip(File tempZip, int myGen) async {
    final client = http.Client();
    final prev = _httpClient;
    if (prev != null && prev != client) {
      prev.close();
    }
    _httpClient = client;

    try {
      final request = http.Request('GET', Uri.parse(_zipUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException(
          'HTTP ${response.statusCode} downloading tajweed ZIP',
        );
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;
      final sink = tempZip.openWrite();
      var sinkClosed = false;

      try {
        await for (final chunk in response.stream) {
          if (_currentGeneration != myGen) {
            return;
          }
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            _downloadProgress = receivedBytes / totalBytes;
            notifyListeners();
          }
        }

        await sink.flush();
      } finally {
        if (!sinkClosed) {
          sinkClosed = true;
          await sink.close();
        }
      }
    } finally {
      client.close();
      if (_httpClient == client) _httpClient = null;
    }
  }

  /// Extracts the ZIP in an isolate using file-backed streams to reduce memory use.
  static void _extractZipEntryPoint(Map<String, Object?> message) {
    final sendPort = message['sendPort'] as SendPort;
    final zipPath = message['zipPath'] as String;
    final outDir = message['outDir'] as String;

    InputFileStream? inputStream;
    try {
      inputStream = InputFileStream(zipPath);
      final archive = ZipDecoder().decodeStream(inputStream);
      final pngEntries = archive
          .where(
            (entry) => entry.isFile && entry.name.toLowerCase().endsWith('.png'),
          )
          .toList(growable: false);

      sendPort.send({'type': 'count', 'total': pngEntries.length});

      var extracted = 0;
      for (final entry in pngEntries) {
        final outFile = File('$outDir/${entry.name}');
        outFile.parent.createSync(recursive: true);

        final outputStream = OutputFileStream(outFile.path);
        try {
          entry.writeContent(outputStream);
        } finally {
          outputStream.closeSync();
        }

        extracted++;
        if (extracted == pngEntries.length || extracted % 25 == 0) {
          sendPort.send({'type': 'progress', 'done': extracted});
        }
      }

      sendPort.send({'type': 'done'});
    } catch (e, stackTrace) {
      sendPort.send(
        {
          'type': 'error',
          'message': '$e',
          'stackTrace': '$stackTrace',
        },
      );
    } finally {
      inputStream?.closeSync();
    }
  }

  /// Spot-check that a few representative images were extracted.
  Future<bool> _verify(String baseDir) async {
    const checks = ['1/1/1.png', '36/1/1.png', '114/1/1.png'];
    for (final rel in checks) {
      final f = File('$baseDir/$rel');
      if (!await f.exists()) return false;
      final len = await f.length();
      if (len < 100) return false;
    }
    return true;
  }
}
