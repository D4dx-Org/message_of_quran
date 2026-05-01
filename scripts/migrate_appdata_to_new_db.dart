// migrate_appdata_to_new_db.dart
//
// One-time build-time script that migrates data from `app_data.db` into
// `quran_malayalam_.db`.
//
// Tables migrated:
//   tbl_arabic        → arabic_ayahs
//   tbl_juzz          → juzzs
//   tbl_hizb          → hizbs
//   tbl_tajweed_words → tajweed_words
//   preface           → prefaces
//
// Run from the repo root:
//   dart run scripts/migrate_appdata_to_new_db.dart

import 'dart:convert';
import 'dart:io';

const srcDb = 'assets/db/app_data.db';
const dstDb = 'assets/db/quran_malayalam_.db';
const sqlTmp = 'scripts/_migrate_appdata.sql';
const sqlite3 =
    r'C:\Users\rosha\AppData\Local\Android\Sdk\platform-tools\sqlite3.exe';

/// Default values for NOT NULL metadata columns in the new schema.
const _createdBy = 'migration';
const _createdByRole = 'creator';
const _now = '2026-04-27T00:00:00Z';

void main() async {
  for (final f in [srcDb, dstDb, sqlite3]) {
    if (!File(f).existsSync()) {
      stderr.writeln('ERROR: Not found: $f');
      exit(1);
    }
  }

  Future<List<Map<String, String>>> readTable(String table) async {
    final res = await Process.run(
      sqlite3,
      [srcDb, '-json', 'SELECT * FROM $table;'],
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

  stdout.writeln('Reading tables from $srcDb...');
  final arabicRows = await readTable('tbl_arabic');
  final juzzRows = await readTable('tbl_juzz');
  final hizbRows = await readTable('tbl_hizb');
  final tajweedRows = await readTable('tbl_tajweed_words');
  final prefaceRows = await readTable('preface WHERE status = 0');
  stdout.writeln(
    'tbl_arabic:${arabicRows.length}  tbl_juzz:${juzzRows.length}  '
    'tbl_hizb:${hizbRows.length}  tbl_tajweed_words:${tajweedRows.length}  '
    'preface:${prefaceRows.length}',
  );

  // Metadata defaults shared by every INSERT.
  const meta =
      "'$_createdBy','$_createdByRole',NULL,NULL,0,'$_now','$_now'";

  final buf = StringBuffer();
  buf.writeln('PRAGMA journal_mode=DELETE;');
  buf.writeln('BEGIN TRANSACTION;');

  // ─── arabic_ayahs ───
  buf.writeln('DELETE FROM arabic_ayahs;');
  for (final r in arabicRows) {
    final id = r['_id'] ?? '0';
    buf.writeln(
      "INSERT INTO arabic_ayahs "
      "(id, custom_id, chapter_no, verse_from, verse_to, data_arabic, position, "
      "created_by, created_by_role, verified_by, verified_at, is_verified, created_at, updated_at) "
      "VALUES ('arabic_$id',${_i(id)},${_i(r['chapter_no'])},${_i(r['verse_from'])},${_i(r['verse_to'])},${_v(r['data_arabic'])},${_i(r['position'])},$meta);",
    );
  }

  // ─── juzzs ───
  buf.writeln('DELETE FROM juzzs;');
  for (final r in juzzRows) {
    final id = r['_id'] ?? '0';
    buf.writeln(
      "INSERT INTO juzzs "
      "(id, custom_id, chapter_no, verse_no, position, "
      "created_by, created_by_role, verified_by, verified_at, is_verified, created_at, updated_at) "
      "VALUES ('juz_$id',${_i(id)},${_i(r['chapter_no'])},${_i(r['verse_no'])},${_i(r['position'])},$meta);",
    );
  }

  // ─── hizbs ───
  buf.writeln('DELETE FROM hizbs;');
  for (final r in hizbRows) {
    final id = r['_id'] ?? '0';
    buf.writeln(
      "INSERT INTO hizbs "
      "(id, custom_id, chapter_no, verse_no, position, "
      "created_by, created_by_role, verified_by, verified_at, is_verified, created_at, updated_at) "
      "VALUES ('hizb_$id',${_i(id)},${_i(r['chapter_no'])},${_i(r['verse_no'])},${_i(r['position'])},$meta);",
    );
  }

  // ─── tajweed_words ───
  buf.writeln('DELETE FROM tajweed_words;');
  for (final r in tajweedRows) {
    final id = r['id'] ?? '0';
    buf.writeln(
      "INSERT INTO tajweed_words "
      "(id, custom_id, surah_no, ayah_no, word_pos, word_text, image_url, "
      "created_by, created_by_role, verified_by, verified_at, is_verified, created_at, updated_at) "
      "VALUES ('tw_$id',${_i(id)},${_i(r['surah_no'])},${_i(r['ayah_no'])},${_i(r['word_pos'])},${_v(r['word_text'])},${_v(r['image_url'])},$meta);",
    );
  }

  // ─── prefaces (column rename: PascalCase → snake_case) ───
  buf.writeln('DELETE FROM prefaces;');
  for (final r in prefaceRows) {
    final id = r['ID'] ?? '0';
    buf.writeln(
      "INSERT INTO prefaces "
      "(id, custom_id, preface_sub_title, preface_text, sura_id, "
      "created_by, created_by_role, verified_by, verified_at, is_verified, created_at, updated_at) "
      "VALUES ('pref_$id',${_i(id)},${_v(r['PrefaceSubTitle'])},${_v(r['PrefaceText'])},${_i(r['SuraId'])},$meta);",
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

  // Verify row counts match source.
  stdout.writeln('\nVerification (destination row counts):');
  for (final t in [
    'arabic_ayahs',
    'juzzs',
    'hizbs',
    'tajweed_words',
    'prefaces',
  ]) {
    final v = await Process.run(
      sqlite3,
      [dstDb, 'SELECT COUNT(*) FROM $t;'],
      stdoutEncoding: utf8,
    );
    stdout.writeln('  $t: ${v.stdout.toString().trim()} rows');
  }
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
