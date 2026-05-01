import 'dart:convert';
import 'dart:io';

const srcDb   = 'assets/db/thafheem_v12.db';
const dstDb   = 'assets/db/app_data.db';
const sqlTmp  = 'scripts/_migrate_preface.sql';
const sqlite3 = r'C:\Users\rosha\AppData\Local\Android\Sdk\platform-tools\sqlite3.exe';

void main() async {
  for (final f in [srcDb, dstDb, sqlite3]) {
    if (!File(f).existsSync()) { stderr.writeln('ERROR: Not found: $f'); exit(1); }
  }

  Future<List<Map<String, String>>> readTable(String table) async {
    final res = await Process.run(
      sqlite3, [srcDb, '-json', 'SELECT * FROM $table;'],
      stdoutEncoding: utf8, stderrEncoding: utf8,
    );
    if (res.exitCode != 0) { stderr.writeln('ERROR reading $table: ${res.stderr}'); exit(1); }
    final raw = res.stdout.toString().trim();
    if (raw.isEmpty) return [];
    return (jsonDecode(raw) as List).map((e) =>
      (e as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))).toList();
  }

  stdout.writeln('Reading preface table from $srcDb...');
  final rows = await readTable('preface');
  stdout.writeln('preface: ${rows.length} rows');

  final buf = StringBuffer();
  buf.writeln('PRAGMA journal_mode=DELETE;');
  buf.writeln('BEGIN TRANSACTION;');
  buf.writeln('DROP TABLE IF EXISTS preface;');
  buf.writeln('CREATE TABLE preface (ID INTEGER PRIMARY KEY, PrefaceSubTitle TEXT, PrefaceText TEXT, SuraId INTEGER, status INTEGER);');
  for (final r in rows) {
    buf.writeln("INSERT INTO preface VALUES (${_i(r['ID'])},${_v(r['PrefaceSubTitle'])},${_v(r['PrefaceText'])},${_i(r['SuraId'])},${_i(r['status'])});");
  }
  buf.writeln('COMMIT;');
  buf.writeln('VACUUM;');

  File(sqlTmp).writeAsStringSync(buf.toString());
  stdout.writeln('Applying SQL to $dstDb ...');
  final res = await Process.run(sqlite3, [dstDb, '.read $sqlTmp'], stdoutEncoding: utf8, stderrEncoding: utf8);
  if (res.stdout.toString().isNotEmpty) stdout.write(res.stdout);
  if (res.stderr.toString().isNotEmpty) stderr.write(res.stderr);
  File(sqlTmp).deleteSync();
  if (res.exitCode != 0) { stderr.writeln('sqlite3 exited with ${res.exitCode}'); exit(res.exitCode); }

  final v = await Process.run(sqlite3, [dstDb, 'SELECT COUNT(*) FROM preface;'], stdoutEncoding: utf8);
  stdout.writeln('  preface: ${v.stdout.toString().trim()} rows in $dstDb');
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
