import 'dart:typed_data';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

Future<void> deleteFileIfExists(String path) async {
  // No file system on web; handled by databaseFactory.
}

Future<void> createDirectoryRecursive(String path) async {
  // No file system on web.
}

Future<void> writeFileBytes(String path, List<int> bytes) async {
  // No file system on web; use writeAssetDatabase instead.
}

Future<bool> fileExistsAt(String path) async {
  return false;
}

Future<void> deleteWalShmFiles(String dbPath) async {
  // WAL/SHM files don't exist on web.
}

/// Set the global databaseFactory to the web FFI implementation.
void initDatabaseFactory() {
  sqflite.databaseFactory = databaseFactoryFfiWeb;
}

/// On web, write database bytes via the web databaseFactory.
Future<void> writeAssetDatabase(String dbPath, List<int> bytes) async {
  await databaseFactoryFfiWeb.writeDatabaseBytes(
    dbPath,
    Uint8List.fromList(bytes),
  );
}

/// On web, use the web databaseFactory to check existence.
Future<bool> databaseExistsAt(String path) async {
  return databaseFactoryFfiWeb.databaseExists(path);
}
