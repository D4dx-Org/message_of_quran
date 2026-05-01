import 'dart:convert';
import 'dart:io';

const srcDb   = 'assets/db/database.db';
const dstDb   = 'assets/db/quranmalayalamtranlationv7.db';
const sqlTmp  = 'scripts/_migrate_info.sql';
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

  stdout.writeln('Reading tables from $srcDb...');
  final aboutRows   = await readTable('about_us');
  final contactRows = await readTable('contact_us');
  final authorRows  = await readTable('authors');
  final helpRows    = await readTable('helps');
  stdout.writeln('about_us:${aboutRows.length}  contact_us:${contactRows.length}  authors:${authorRows.length}  helps:${helpRows.length}');

  final buf = StringBuffer();
  buf.writeln('PRAGMA journal_mode=DELETE;');
  buf.writeln('BEGIN TRANSACTION;');

  buf.writeln('DROP TABLE IF EXISTS about_us;');
  buf.writeln('CREATE TABLE about_us (id TEXT, title TEXT, description TEXT, created_by TEXT, created_by_role TEXT, is_verified INTEGER);');
  for (final r in aboutRows) {
    buf.writeln("INSERT INTO about_us VALUES (${_v(r['id'])},${_v(r['title'])},${_v(r['description'])},${_v(r['created_by'])},${_v(r['created_by_role'])},${_i(r['is_verified'])});");
  }

  buf.writeln('DROP TABLE IF EXISTS contact_us;');
  buf.writeln('CREATE TABLE contact_us (id TEXT, mobile TEXT, whatsapp TEXT, email TEXT, address TEXT, remarks TEXT, created_by TEXT, created_by_role TEXT, is_verified INTEGER);');
  for (final r in contactRows) {
    buf.writeln("INSERT INTO contact_us VALUES (${_v(r['id'])},${_v(r['mobile'])},${_v(r['whatsapp'])},${_v(r['email'])},${_v(r['address'])},${_v(r['remarks'])},${_v(r['created_by'])},${_v(r['created_by_role'])},${_i(r['is_verified'])});");
  }

  buf.writeln('DROP TABLE IF EXISTS authors;');
  buf.writeln('CREATE TABLE authors (id TEXT, html_content TEXT, created_by TEXT, created_by_role TEXT, is_verified INTEGER);');
  for (final r in authorRows) {
    buf.writeln("INSERT INTO authors VALUES (${_v(r['id'])},${_v(r['html_content'])},${_v(r['created_by'])},${_v(r['created_by_role'])},${_i(r['is_verified'])});");
  }

  buf.writeln('DROP TABLE IF EXISTS helps;');
  buf.writeln('CREATE TABLE helps (id TEXT, title TEXT, description TEXT, display_order INTEGER, created_by TEXT, created_by_role TEXT, is_verified INTEGER);');
  for (final r in helpRows) {
    buf.writeln("INSERT INTO helps VALUES (${_v(r['id'])},${_v(r['title'])},${_v(r['description'])},${_i(r['display_order'])},${_v(r['created_by'])},${_v(r['created_by_role'])},${_i(r['is_verified'])});");
  }

  buf.writeln('COMMIT;');
  buf.writeln('VACUUM;');

  File(sqlTmp).writeAsStringSync(buf.toString());
  stdout.writeln('Applying SQL to $dstDb ...');

  final res = await Process.run(
    sqlite3, [dstDb, '.read $sqlTmp'],
    stdoutEncoding: utf8, stderrEncoding: utf8,
  );
  if (res.stdout.toString().isNotEmpty) stdout.write(res.stdout);
  if (res.stderr.toString().isNotEmpty) stderr.write(res.stderr);
  File(sqlTmp).deleteSync();

  if (res.exitCode != 0) { stderr.writeln('sqlite3 exited with ${res.exitCode}'); exit(res.exitCode); }

  for (final t in ['about_us', 'contact_us', 'authors', 'helps']) {
    final v = await Process.run(sqlite3, [dstDb, 'SELECT COUNT(*) FROM $t;'], stdoutEncoding: utf8);
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
