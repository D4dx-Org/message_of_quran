// migrate_arabic_from_thafheem.dart
//
// Migrates Arabic ayah text from `thafheem_static.sqlite` into
// `quran_malayalam_.db`, using the same verse grouping ranges as the
// existing `arabic_ayahs_old` table.
//
// For each block in the old table (chapter_no, verse_from, verse_to),
// concatenates the matching AyaHText rows from thafheem into a single
// data_arabic string — preserving the grouped-range display pattern.
//
// Run from the repo root:
//   dart run scripts/migrate_arabic_from_thafheem.dart

import 'dart:convert';
import 'dart:io';

const srcDb = 'assets/db/thafheem_static.sqlite';
const dstDb = 'assets/db/quran_malayalam_.db';
const sqlTmp = 'scripts/_migrate_arabic_thafheem.sql';
const sqlite3 =
    r'C:\Users\rosha\AppData\Local\Android\Sdk\platform-tools\sqlite3.exe';

const _createdBy = 'migration';
const _createdByRole = 'creator';
const _now = '2026-04-28T00:00:00Z';

void main() async {
  for (final f in [srcDb, dstDb, sqlite3]) {
    if (!File(f).existsSync()) {
      stderr.writeln('ERROR: Not found: $f');
      exit(1);
    }
  }

  Future<List<Map<String, String>>> readTable(String db, String sql) async {
    final res = await Process.run(
      sqlite3,
      [db, '-json', sql],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (res.exitCode != 0) {
      stderr.writeln('ERROR: ${res.stderr}');
      exit(1);
    }
    final raw = res.stdout.toString().trim();
    if (raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => (e as Map)
            .map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
        .toList();
  }

  // ─── Read old groupings to replicate the same verse ranges ───
  stdout.writeln('Reading old groupings from $dstDb (arabic_ayahs_old)...');
  final oldBlocks = await readTable(
    dstDb,
    'SELECT custom_id, chapter_no, verse_from, verse_to, position FROM arabic_ayahs_old ORDER BY position ASC;',
  );
  stdout.writeln('Old blocks: ${oldBlocks.length} groups');

  // ─── Read all ayahs from thafheem ───
  stdout.writeln('Reading arabic_text from $srcDb...');
  final ayahRows = await readTable(
    srcDb,
    'SELECT suraid, ayaid, AyaHText FROM arabic_text ORDER BY contiayano;',
  );
  stdout.writeln('Thafheem ayahs: ${ayahRows.length} rows');

  if (ayahRows.isEmpty || oldBlocks.isEmpty) {
    stderr.writeln('No data found. Aborting.');
    exit(1);
  }

  // ─── Index ayahs by (suraid, ayaid) for fast lookup ───
  final ayahMap = <String, String>{};
  for (final r in ayahRows) {
    final key = '${r['suraid']}_${r['ayaid']}';
    ayahMap[key] = r['AyaHText'] ?? '';
  }

  // Metadata defaults shared by every INSERT.
  const meta = "'$_createdBy','$_createdByRole',NULL,NULL,0,'$_now','$_now'";

  final buf = StringBuffer();
  buf.writeln('PRAGMA journal_mode=DELETE;');
  buf.writeln('BEGIN TRANSACTION;');

  // ─── Drop and recreate arabic_ayahs (old is already preserved) ───
  buf.writeln('DROP TABLE IF EXISTS arabic_ayahs;');

  // ─── Recreate arabic_ayahs with the same schema ───
  buf.writeln('''
CREATE TABLE arabic_ayahs (
  id TEXT PRIMARY KEY,
  custom_id INTEGER,
  chapter_no INTEGER,
  verse_from INTEGER,
  verse_to INTEGER,
  data_arabic TEXT,
  position INTEGER,
  created_by TEXT,
  created_by_role TEXT,
  verified_by TEXT,
  verified_at TEXT,
  is_verified INTEGER,
  created_at TEXT,
  updated_at TEXT
);
''');

  // ─── Build grouped inserts using old ranges ───
  int inserted = 0;
  int missing = 0;
  for (final block in oldBlocks) {
    final chapterNo = int.tryParse(block['chapter_no'] ?? '') ?? 0;
    final verseFrom = int.tryParse(block['verse_from'] ?? '') ?? 0;
    final verseTo = int.tryParse(block['verse_to'] ?? '') ?? 0;
    final position = block['position'] ?? '0';
    final customId = block['custom_id'] ?? position;

    // Concatenate ayah texts for this range
    final textParts = <String>[];
    for (int ayah = verseFrom; ayah <= verseTo; ayah++) {
      final key = '${chapterNo}_$ayah';
      final text = ayahMap[key];
      if (text != null && text.isNotEmpty) {
        textParts.add(text);
      } else {
        missing++;
      }
    }

    final combinedText = textParts.join('');

    buf.writeln(
      "INSERT INTO arabic_ayahs "
      "(id, custom_id, chapter_no, verse_from, verse_to, data_arabic, position, "
      "created_by, created_by_role, verified_by, verified_at, is_verified, created_at, updated_at) "
      "VALUES ('arabic_$customId',${_i(customId)},${_i(block['chapter_no'])},${_i(block['verse_from'])},${_i(block['verse_to'])},${_v(combinedText)},${_i(position)},$meta);",
    );
    inserted++;
  }

  buf.writeln('COMMIT;');
  buf.writeln('VACUUM;');

  File(sqlTmp).writeAsStringSync(buf.toString());
  stdout.writeln('Inserting $inserted grouped blocks ($missing missing ayahs)...');
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

  // Verify row counts.
  stdout.writeln('\nVerification:');
  for (final t in ['arabic_ayahs', 'arabic_ayahs_old']) {
    final v = await Process.run(
      sqlite3,
      [dstDb, 'SELECT COUNT(*) FROM $t;'],
      stdoutEncoding: utf8,
    );
    stdout.writeln('  $t: ${v.stdout.toString().trim()} rows');
  }

  // Spot-check Al-Fatiha.
  final check = await Process.run(
    sqlite3,
    [
      dstDb,
      '-json',
      'SELECT chapter_no, verse_from, verse_to, substr(data_arabic,1,60) as preview FROM arabic_ayahs WHERE chapter_no=1 ORDER BY verse_from;'
    ],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  stdout.writeln('\nAl-Fatiha spot-check:');
  stdout.writeln(check.stdout);

  // Spot-check Al-Baqarah first few blocks.
  final check2 = await Process.run(
    sqlite3,
    [
      dstDb,
      '-json',
      'SELECT chapter_no, verse_from, verse_to FROM arabic_ayahs WHERE chapter_no=2 ORDER BY verse_from LIMIT 5;'
    ],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  stdout.writeln('\nAl-Baqarah first blocks:');
  stdout.writeln(check2.stdout);

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
