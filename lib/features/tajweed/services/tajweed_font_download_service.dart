import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' show min;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Downloads, verifies, and manages the 604-page QCF V4 Tajweed COLR font pack.
///
/// Each page font is stored as `p{N}.ttf` inside `{docsDir}/tajweed_fonts/`.
/// The family naming convention used by [TajweedFontService] is `TAJWEED_PNNN`.
class TajweedFontDownloadService {
  TajweedFontDownloadService._();

  static final TajweedFontDownloadService instance =
      TajweedFontDownloadService._();

  // ── Constants ──────────────────────────────────────────────────────
  static const int _totalPages = 604;
  static const String _cdnBase =
      'https://quran.com/fonts/quran/hafs/v4/colrv1/ttf';
  static const String _installedKey = 'tajweed_fonts_installed';
  static const String _versionKey = 'tajweed_fonts_version';
  static const int _currentVersion = 1;
  static const int _batchSize = 10;
  static const String _migrationKey = 'tajweed_migration_v2_done';

  bool _isCancelled = false;
  http.Client? _client;

  // ── Directory ──────────────────────────────────────────────────────

  Future<Directory> get fontsDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/tajweed_fonts');
    await dir.create(recursive: true);
    return dir;
  }

  // ── Install check ─────────────────────────────────────────────────

  Future<bool> get isInstalled async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_installedKey) ?? false)) return false;
    final dir = await fontsDir;
    final count = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ttf'))
        .length;
    return count >= _totalPages;
  }

  /// Returns the local [File] for a page font, or `null` if not installed.
  Future<File?> fontFileForPage(int pageNo) async {
    final dir = await fontsDir;
    final f = File('${dir.path}/p$pageNo.ttf');
    if (await f.exists()) return f;
    return null;
  }

  // ── Download ──────────────────────────────────────────────────────

  /// Streams [0..1] download progress and completes when all 604 fonts are
  /// downloaded and verified.
  Stream<double> downloadFontPack() async* {
    _isCancelled = false;
    _client = http.Client();

    final dir = await fontsDir;
    yield 0.01;

    // Collect missing pages only (resume-friendly).
    final missing = <int>[];
    for (var i = 1; i <= _totalPages; i++) {
      final f = File('${dir.path}/p$i.ttf');
      if (!f.existsSync() || (await f.length()) < 1000) missing.add(i);
    }

    if (missing.isEmpty) {
      await _markInstalled();
      yield 1.0;
      return;
    }

    final total = missing.length;
    var done = 0;

    for (var i = 0; i < total; i += _batchSize) {
      if (_isCancelled) return;

      final end = min(i + _batchSize, total);
      final batch = missing.sublist(i, end);

      var retries = 0;
      while (true) {
        try {
          await Future.wait(
            batch.map((p) => _downloadPage(dir, p)),
          );
          break;
        } catch (e) {
          if (_isCancelled) return;
          retries++;
          if (retries >= 3) rethrow;
          await Future<void>.delayed(Duration(seconds: retries * 2));
        }
      }

      done += batch.length;
      yield done / total;
    }

    if (_isCancelled) return;

    final verified = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ttf'))
        .length;
    if (verified < _totalPages) {
      throw Exception(
        'Tajweed font install incomplete: $verified of $_totalPages pages.',
      );
    }

    await _markInstalled();
    yield 1.0;
  }

  Future<void> _downloadPage(Directory dir, int pageNo) async {
    final url = '$_cdnBase/p$pageNo.ttf';
    final client = _client;
    if (client == null) throw Exception('Download cancelled');

    final response = await client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} for $url');
    }

    final file = File('${dir.path}/p$pageNo.ttf');
    await file.writeAsBytes(response.bodyBytes);
    log('TajweedFontDownload: downloaded p$pageNo.ttf');
  }

  Future<void> _markInstalled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_installedKey, true);
    await prefs.setInt(_versionKey, _currentVersion);
  }

  // ── Cancel / Delete ───────────────────────────────────────────────

  void cancel() {
    _isCancelled = true;
    _client?.close();
    _client = null;
  }

  Future<void> deleteFontPack() async {
    cancel();
    final dir = await fontsDir;
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      log('TajweedFontDownload: font pack deleted');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_installedKey);
    await prefs.remove(_versionKey);
  }

  // ── Startup migration ─────────────────────────────────────────────

  /// One-time migration: removes any old image-based Tajweed cache directories
  /// left by the previous implementation.
  static Future<void> runMigrationIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) ?? false) return;

    try {
      final docs = await getApplicationDocumentsDirectory();
      for (final staleDir in ['tajweed_words', 'tajweed_word_cache', 'tajweed_images']) {
        final d = Directory('${docs.path}/$staleDir');
        if (d.existsSync()) {
          await d.delete(recursive: true);
          log('TajweedMigration: removed $staleDir');
        }
      }

      // Remove old preference keys from the image-based pipeline.
      await prefs.remove('tajweed_download_complete');

      await prefs.setBool(_migrationKey, true);
      log('TajweedMigration: v2 migration completed');
    } catch (e) {
      log('TajweedMigration: migration failed (non-fatal): $e');
    }
  }
}
