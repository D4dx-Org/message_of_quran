import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

/// File-system backed font store used on Android, iOS, and desktop.
class MushafFontStore {
  MushafFontStore._();

  static const String _kSubDir = 'mushaf_fonts';
  static const List<String> _kVerifyFiles = [
    'QCF_P003.TTF',
    'QCF_P100.TTF',
    'QCF_P602.TTF',
  ];

  static Future<Directory> fontsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_kSubDir');
    await dir.create(recursive: true);
    return dir;
  }

  /// Decodes [zipBytes] in memory and writes each TTF entry to the fonts dir.
  static Future<void> extractAndStoreFromZipBytes(Uint8List zipBytes) async {
    final dir = await fontsDirectory();
    final archive = ZipDecoder().decodeBytes(zipBytes);
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
      final outFile = File('${dir.path}/$name');
      await outFile.writeAsBytes(data, flush: true);
    }
  }

  static Future<Uint8List?> loadFont(String name) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final file = File('${docs.path}/$_kSubDir/$name');
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasFont(String name) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final file = File('${docs.path}/$_kSubDir/$name');
      if (!await file.exists()) return false;
      return (await file.length()) > 1000;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearAll() async {
    try {
      final dir = await fontsDirectory();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  static Future<bool> verify() async {
    for (final name in _kVerifyFiles) {
      if (!await hasFont(name)) return false;
    }
    return true;
  }
}
