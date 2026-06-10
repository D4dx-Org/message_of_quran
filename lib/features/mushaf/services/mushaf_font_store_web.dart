import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:web/web.dart';

/// IndexedDB-backed font store used on web.
///
/// Each TTF file is stored as an ArrayBuffer under the key of its filename
/// (e.g. `QCF_P003.TTF`) in the `fonts` object store of the
/// `mushaf_fonts_db` IndexedDB database.  Data persists across browser
/// sessions, matching the file-system behaviour on native platforms.
class MushafFontStore {
  MushafFontStore._();

  static const String _kDbName = 'mushaf_fonts_db';
  static const String _kStoreName = 'fonts';
  static const int _kDbVersion = 1;
  static const List<String> _kVerifyFiles = [
    'QCF_P003.TTF',
    'QCF_P100.TTF',
    'QCF_P602.TTF',
  ];

  static Future<IDBDatabase> _openDb() {
    final completer = Completer<IDBDatabase>();
    final request = window.indexedDB.open(_kDbName, _kDbVersion);
    request.onupgradeneeded = ((Event event) {
      final db = request.result as IDBDatabase;
      final names = db.objectStoreNames;
      var found = false;
      for (var i = 0; i < names.length; i++) {
        if (names.item(i) == _kStoreName) {
          found = true;
          break;
        }
      }
      if (!found) db.createObjectStore(_kStoreName);
    }).toJS;
    request.onsuccess = ((Event event) {
      completer.complete(request.result as IDBDatabase);
    }).toJS;
    request.onerror = ((Event event) {
      completer.completeError(Exception('Failed to open IndexedDB: $_kDbName'));
    }).toJS;
    return completer.future;
  }

  /// Decodes [zipBytes] in memory and stores each TTF entry in IndexedDB.
  static Future<void> extractAndStoreFromZipBytes(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final db = await _openDb();
    try {
      final txn = db.transaction(_kStoreName.toJS, 'readwrite');
      final store = txn.objectStore(_kStoreName);
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
        // Store as Uint8Array so it round-trips correctly through IndexedDB.
        store.put(Uint8List.fromList(data).toJS, name.toJS);
      }
      final completer = Completer<void>();
      txn.oncomplete = ((Event _) => completer.complete()).toJS;
      txn.onerror = ((Event _) =>
          completer.completeError(Exception('Write transaction failed'))).toJS;
      await completer.future;
    } finally {
      db.close();
    }
  }

  static Future<Uint8List?> loadFont(String name) async {
    try {
      final db = await _openDb();
      final txn = db.transaction(_kStoreName.toJS, 'readonly');
      final store = txn.objectStore(_kStoreName);
      final request = store.get(name.toJS);
      final completer = Completer<Uint8List?>();
      request.onsuccess = ((Event event) {
        final result = request.result;
        if (result == null) {
          completer.complete(null);
        } else if (result.isA<JSUint8Array>()) {
          completer.complete((result as JSUint8Array).toDart);
        } else if (result.isA<JSArrayBuffer>()) {
          completer.complete(
              (result as JSArrayBuffer).toDart.asUint8List());
        } else {
          completer.complete(null);
        }
      }).toJS;
      request.onerror = ((Event _) => completer.complete(null)).toJS;
      final result = await completer.future;
      db.close();
      return result;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasFont(String name) async {
    final bytes = await loadFont(name);
    return bytes != null && bytes.length > 1000;
  }

  static Future<void> clearAll() async {
    try {
      final db = await _openDb();
      final txn = db.transaction(_kStoreName.toJS, 'readwrite');
      final store = txn.objectStore(_kStoreName);
      final request = store.clear();
      final completer = Completer<void>();
      request.onsuccess = ((Event _) => completer.complete()).toJS;
      request.onerror = ((Event _) => completer.complete()).toJS;
      await completer.future;
      db.close();
    } catch (_) {}
  }

  static Future<bool> verify() async {
    for (final name in _kVerifyFiles) {
      if (!await hasFont(name)) return false;
    }
    return true;
  }
}
