import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

Future<void> deleteFileIfExists(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}
}

Future<void> createDirectoryRecursive(String path) async {
  try {
    await Directory(dirname(path)).create(recursive: true);
  } catch (_) {}
}

Future<void> writeFileBytes(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

Future<bool> fileExistsAt(String path) async {
  return File(path).exists();
}

Future<void> deleteWalShmFiles(String dbPath) async {
  for (final suffix in ['-wal', '-shm']) {
    await deleteFileIfExists('$dbPath$suffix');
  }
}

/// No-op on native — factory is already set.
void initDatabaseFactory() {}

/// On native, copy asset bytes to the file system.
Future<void> writeAssetDatabase(String dbPath, List<int> bytes) async {
  await createDirectoryRecursive(dbPath);
  await deleteWalShmFiles(dbPath);
  await deleteFileIfExists(dbPath);
  await writeFileBytes(dbPath, bytes);
}

/// On native, use sqflite's databaseExists.
Future<bool> databaseExistsAt(String path) async {
  return sqflite.databaseExists(path);
}
