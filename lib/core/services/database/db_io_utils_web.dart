import 'dart:typed_data';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

// sqlite3.wasm is resolved by the package via `Uri.base` (the current
// browser URL), not the document's <base href>. With go_router path-based
// URLs, opening the app on a nested route (e.g. /surah/18) would otherwise
// resolve the relative default 'sqlite3.wasm' to the wrong path
// (/surah/sqlite3.wasm). Pin it to a root-absolute path instead.
final sqflite.DatabaseFactory _webDatabaseFactory = createDatabaseFactoryFfiWeb(
  noWebWorker: true,
  options: SqfliteFfiWebOptions(sqlite3WasmUri: Uri.parse('/sqlite3.wasm')),
);

Future<void> deleteFileIfExists(String path) async {
  try {
    await _webDatabaseFactory.deleteDatabase(path);
  } catch (_) {}
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
  sqflite.databaseFactory = _webDatabaseFactory;
}

/// On web, write database bytes via the web databaseFactory.
Future<void> writeAssetDatabase(String dbPath, List<int> bytes) async {
  await _webDatabaseFactory.writeDatabaseBytes(
    dbPath,
    Uint8List.fromList(bytes),
  );
}

/// On web, use the web databaseFactory to check existence.
Future<bool> databaseExistsAt(String path) async {
  try {
    return await _webDatabaseFactory.databaseExists(path);
  } catch (_) {
    return false;
  }
}
