// migrate_preface_from_new_db.dart
//
// Migrates preface data from `quran_malayalam.db` into `quran_malayalam_.db`,
// replacing all existing preface rows.
//
// Run from the repo root:
//   dart run scripts/migrate_preface_from_new_db.dart

import 'dart:convert';
import 'dart:io';

const srcDb = 'assets/db/quran_malayalam.db';
const dstDb = 'assets/db/quran_malayalam_.db';
const sqlTmp = 'scripts/_migrate_preface_new.sql';
const sqlite3 =
    r'C:\Users\rosha\AppData\Local\Android\Sdk\platform-tools\sqlite3.exe';

void main() async {
  for (final f in [srcDb, dstDb, sqlite3]) {
    if (!File(f).existsSync()) {
      stderr.writeln('ERROR: Not found: $f');
      exit(1);
    }
  }

  Future<List<Map<String, String>>> readTable(String db, String table) async {
    final res = await Process.run(
      sqlite3,
      [db, '-json', 'SELECT * FROM $table;'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (res.exitCode != 0) {
      stderr.writeln('ERROR reading $table: ${res.stderr}');
      exit(1);
    }
    final raw = res.stdout.toString().trim();
    if (raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => (e as Map)
            .map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
        .toList();
  }

  stdout.writeln('Reading prefaces from $srcDb...');
  final rows = await readTable(srcDb, 'prefaces');
  stdout.writeln('prefaces: ${rows.length} rows');

  if (rows.isEmpty) {
    stderr.writeln('No preface rows found in source. Aborting.');
    exit(1);
  }

  final buf = StringBuffer();
  buf.writeln('PRAGMA journal_mode=DELETE;');
  buf.writeln('BEGIN TRANSACTION;');
  buf.writeln('DELETE FROM prefaces;');

  for (final r in rows) {
    buf.writeln(
      "INSERT INTO prefaces "
      "(id, custom_id, preface_sub_title, preface_text, sura_id, "
      "created_by, created_by_role, verified_by, verified_at, is_verified, created_at, updated_at) "
      "VALUES (${_v(r['id'])},${_i(r['custom_id'])},${_v(r['preface_sub_title'])},${_v(r['preface_text'])},${_i(r['sura_id'])},"
      "${_v(r['created_by'])},${_v(r['created_by_role'])},${_v(r['verified_by'])},${_v(r['verified_at'])},${_i(r['is_verified'])},${_v(r['created_at'])},${_v(r['updated_at'])});",
    );
  }

  buf.writeln('COMMIT;');
  buf.writeln('VACUUM;');

  File(sqlTmp).writeAsStringSync(buf.toString());
  stdout.writeln('Applying SQL to $dstDb ...');

  final res = await Process.run(
    sqlite3,
    [dstDb, '.read $sqlTmp'],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (res.stdout.toString().isNotEmpty) stdout.write(res.stdout);
  if (res.stderr.toString().isNotEmpty) stderr.write(res.stderr);
  File(sqlTmp).deleteSync();

  if (res.exitCode != 0) {
    stderr.writeln('sqlite3 exited with ${res.exitCode}');
    exit(res.exitCode);
  }

  final v = await Process.run(
    sqlite3,
    [dstDb, 'SELECT COUNT(*) FROM prefaces;'],
    stdoutEncoding: utf8,
  );
  stdout.writeln('prefaces: ${v.stdout.toString().trim()} rows in $dstDb');
  stdout.writeln('Done!');
}

String _v(String? s) {
  if (s == null || s.isEmpty) return 'NULL';
  return "'${s.replaceAll("'", "''")}'";
}

String _i(String? s) {
  if (s == null || s.isEmpty) return 'NULL';
  return int.tryParse(s)?.toString() ?? 'NULL';
}
