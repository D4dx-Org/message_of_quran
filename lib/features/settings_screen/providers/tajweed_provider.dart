import 'dart:async';
import 'dart:developer';
import 'dart:io';

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
  String? _downloadError;
  int _currentGeneration = 0;
  http.Client? _httpClient;

  bool get enabled => _enabled;
  bool get isDownloading => _isDownloading;
  bool get isDownloadPaused => _downloadPaused;
  double get downloadProgress => _downloadProgress;
  bool get downloadComplete => _downloadComplete;
  bool get isExtracting => _isExtracting;
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
      _isDownloading = false;
      _isExtracting = false;
      _downloadPaused = false;
      _downloadProgress = 0.0;
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
      await compute(_extractZip, _ExtractArgs(tempZip.path, baseDir));
      if (_currentGeneration != myGen) return;

      // Clean up temp ZIP.
      if (await tempZip.exists()) await tempZip.delete();

      // ── Step 3: Verify ────────────────────────────────────────────
      final ok = await _verify(baseDir);
      if (!ok) {
        throw Exception('Extraction verification failed. Please retry.');
      }

      _isExtracting = false;
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

  /// Extracts the ZIP in an isolate to avoid blocking the UI thread.
  static Future<void> _extractZip(_ExtractArgs args) async {
    final bytes = await File(args.zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = entry.name;
      if (!name.toLowerCase().endsWith('.png')) continue;

      final outFile = File('${args.outDir}/$name');
      await outFile.parent.create(recursive: true);
      final data = entry.content as List<int>;
      await outFile.writeAsBytes(data, flush: true);
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

/// Arguments passed to the isolate for ZIP extraction.
class _ExtractArgs {
  final String zipPath;
  final String outDir;
  const _ExtractArgs(this.zipPath, this.outDir);
}
