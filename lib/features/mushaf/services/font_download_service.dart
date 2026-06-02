import 'dart:developer';
import 'dart:io';
import 'dart:math' show min;

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../db/local_database.dart';
import 'mushaf_install_state.dart';

/// Downloads and installs the Mushaf font pack (pages 3–604).
class FontDownloadService {
  FontDownloadService._();

  static final FontDownloadService instance = FontDownloadService._();

  static const String _baseUrl = 'http://lalithasaram.net/downloads/qfonts/';
  static const int _maxRetries = 3;
  bool _isCancelled = false;

  Future<Directory> get fontsDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/mushaf_fonts');
    await dir.create(recursive: true);
    return dir;
  }

  Stream<double> downloadFontPack() async* {
    _isCancelled = false;
    log('FontDownload: starting font pack download');

    final installState = MushafInstallState.instance;
    await installState.setInstallInProgress(true);

    final outDir = await fontsDir;
    final docs = await getApplicationDocumentsDirectory();

    try {
      yield 0.01;

      final zipNames = await _getPendingZipNames();
      log('FontDownload: ${zipNames.length} pending ZIPs to download');
      if (zipNames.isEmpty) {
        final ok = await _verify(outDir);
        if (ok) {
          await installState.setFullFontsInstalled(value: true);
          yield 1.0;
          return;
        }
      }

      final total = zipNames.length;
      const batchSize = 10;
      final client = http.Client();
      var completed = 0;

      try {
        for (var i = 0; i < total; i += batchSize) {
          if (_isCancelled) {
            await installState.setInstallInProgress(false);
            return;
          }

          final end = min(i + batchSize, total);
          final batch = zipNames.sublist(i, end);

          // Retry the batch on transient network errors.
          var retries = 0;
          while (true) {
            try {
              await Future.wait(
                batch.map((zipName) => _downloadAndExtract(
                      client: client,
                      zipName: zipName,
                      docsDir: docs,
                      outDir: outDir,
                    )),
              );
              break; // success
            } on SocketException catch (e) {
              retries++;
              if (retries >= _maxRetries || _isCancelled) {
                log('FontDownload: network error after $retries retries – $e');
                rethrow;
              }
              log('FontDownload: network error, retry $retries/$_maxRetries – $e');
              await Future.delayed(Duration(seconds: 2 * retries));
            } on http.ClientException catch (e) {
              retries++;
              if (retries >= _maxRetries || _isCancelled) {
                log('FontDownload: client error after $retries retries – $e');
                rethrow;
              }
              log('FontDownload: client error, retry $retries/$_maxRetries – $e');
              await Future.delayed(Duration(seconds: 2 * retries));
            }
          }

          completed += batch.length;
          yield 0.95 * (completed / total);
        }
      } finally {
        client.close();
      }

      yield 0.97;
      final ok = await _verify(outDir);
      if (!ok) {
        throw Exception(
          'Font pack verification failed — some files are missing or corrupt. '
          'Please retry the download.',
        );
      }

      await installState.setFullFontsInstalled(value: true);
      yield 1.0;
    } catch (e) {
      log('FontDownload: ERROR — $e');
      await installState.setInstallInProgress(false);
      rethrow;
    }
  }

  void cancel() => _isCancelled = true;

  Future<void> clearFontPack() async {
    final dir = await fontsDir;
    if (await dir.exists()) await dir.delete(recursive: true);
    await MushafInstallState.instance.setFullFontsInstalled(value: false);
  }

  Future<void> _downloadAndExtract({
    required http.Client client,
    required String zipName,
    required Directory docsDir,
    required Directory outDir,
  }) async {
    final url = '$_baseUrl$zipName.zip';
    final tempFile = File('${docsDir.path}/${zipName}_temp.zip');

    if (await tempFile.exists()) await tempFile.delete();

    final response = await client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception(
        'Download failed for $zipName.zip: HTTP ${response.statusCode}',
      );
    }

    await tempFile.writeAsBytes(response.bodyBytes, flush: true);
    await _extractZip(tempFile, outDir);
    if (await tempFile.exists()) await tempFile.delete();
  }

  Future<List<String>> _getPendingZipNames() async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT fontzip FROM t_linewise_page "
      "WHERE fontstatus=0 AND fontzip != 'f0' "
      "ORDER BY fontzip",
    );
    return rows
        .map((r) => (r['fontzip'] as Object).toString())
        .toList(growable: false);
  }

  Future<void> _extractZip(File zipFile, Directory outDir) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final entry in archive) {
      if (!entry.isFile) continue;
      final rawName = entry.name.split('/').last;
      final name = rawName.toUpperCase();
      if (!name.endsWith('.TTF')) continue;
      final dynamic raw = entry.content;
      if (raw == null) continue;
      final List<int> data =
          raw is List<int> ? raw : List<int>.from(raw as Iterable);
      if (data.isEmpty) continue;
      final outFile = File('${outDir.path}/$name');
      await outFile.writeAsBytes(data, flush: true);
    }
  }

  Future<bool> _verify(Directory dir) async {
    const checkFiles = ['QCF_P003.TTF', 'QCF_P100.TTF', 'QCF_P602.TTF'];
    for (final name in checkFiles) {
      final f = File('${dir.path}/$name');
      final exists = await f.exists();
      final size = exists ? await f.length() : 0;
      if (!exists || size < 1000) return false;
    }
    return true;
  }
}
