// populate_tajweed_db.dart
//
// One-time script that pre-populates `tbl_tajweed_words` (+ its index)
// inside `assets/db/quranmalayalamtranlationv7.db` from the bundled CSV.
//
// Run from the repo root:
//   dart run scripts/populate_tajweed_db.dart
//
// Requires: sqlite3.exe on PATH (available via Android SDK platform-tools).

import 'dart:convert';
import 'dart:io';

const dbPath    = 'assets/db/quranmalayalamtranlationv7.db';
const csvPath   = 'assets/tajweed_words.csv';
const sqlTmp    = 'scripts/_tajweed_import.sql';
const sqlite3   = r'C:\Users\rosha\AppData\Local\Android\Sdk\platform-tools\sqlite3.exe';

const tableName = 'tbl_tajweed_words';
const indexName = 'idx_tajweed_surah_ayah';

void main() async {
  // Validate inputs.
  if (!File(dbPath).existsSync()) {
    stderr.writeln('ERROR: DB not found at $dbPath');
    exit(1);
  }
  if (!File(csvPath).existsSync()) {
    stderr.writeln('ERROR: CSV not found at $csvPath');
    exit(1);
  }
  if (!File(sqlite3).existsSync()) {
    stderr.writeln('ERROR: sqlite3.exe not found at $sqlite3');
    exit(1);
  }

  // Parse CSV.
  final csvContent = File(csvPath).readAsStringSync();
  final lines = csvContent.split('\n');
  // header: "id","suraid","ayaid","word_pos","word_text","image_url","created_at"
  // skip line[0]

  final buffer = StringBuffer();
  buffer.writeln('PRAGMA journal_mode=WAL;');
  buffer.writeln('BEGIN TRANSACTION;');
  buffer.writeln('DROP TABLE IF EXISTS $tableName;');
  buffer.writeln('DROP INDEX IF EXISTS $indexName;');
  buffer.writeln('''
CREATE TABLE $tableName (
  id        INTEGER PRIMARY KEY,
  surah_no  INTEGER NOT NULL,
  ayah_no   INTEGER NOT NULL,
  word_pos  INTEGER NOT NULL,
  word_text TEXT,
  image_url TEXT NOT NULL
);''');
  buffer.writeln(
      'CREATE INDEX $indexName ON $tableName(surah_no, ayah_no);');

  int count = 0;
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    // Fields are double-quoted. Use a simple CSV parse.
    final parts = _parseCsvLine(line);
    if (parts.length < 6) continue;

    final id       = int.tryParse(parts[0]);
    final surahNo  = int.tryParse(parts[1]);
    final ayahNo   = int.tryParse(parts[2]);
    final wordPos  = int.tryParse(parts[3]);
    final wordText = _sqlEscape(parts[4]);
    final imageUrl = _sqlEscape(parts[5]);

    if (id == null || surahNo == null || ayahNo == null ||
        wordPos == null || imageUrl.isEmpty) {
      continue;
    }

    buffer.writeln(
      "INSERT OR IGNORE INTO $tableName VALUES ($id,$surahNo,$ayahNo,$wordPos,'$wordText','$imageUrl');",
    );
    count++;
  }

  buffer.writeln('COMMIT;');
  buffer.writeln('VACUUM;');

  // Write SQL file.
  File(sqlTmp).writeAsStringSync(buffer.toString());
  stdout.writeln('Generated SQL with $count rows. Running sqlite3...');

  // Execute via sqlite3.exe.
  final result = await Process.run(
    sqlite3,
    [dbPath, '.read $sqlTmp'],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
    runInShell: false,
  );

  if (result.stdout.toString().isNotEmpty) stdout.write(result.stdout);
  if (result.stderr.toString().isNotEmpty) stderr.write(result.stderr);

  if (result.exitCode != 0) {
    stderr.writeln('sqlite3 exited with code ${result.exitCode}');
    File(sqlTmp).deleteSync();
    exit(result.exitCode);
  }

  // Cleanup temp SQL file.
  File(sqlTmp).deleteSync();

  // Verify.
  final verify = await Process.run(
    sqlite3,
    [dbPath, 'SELECT COUNT(*) FROM $tableName;'],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final rowCount = verify.stdout.toString().trim();
  stdout.writeln('Done! Rows in $tableName: $rowCount (expected $count)');
  stdout.writeln('Index $indexName created.');
  stdout.writeln('DB: $dbPath');
}

/// Escapes single quotes for SQLite string literals.
String _sqlEscape(String s) => s.replaceAll("'", "''");

/// Parses one CSV line where fields may be double-quoted.
List<String> _parseCsvLine(String line) {
  final result = <String>[];
  var inQuotes = false;
  final current = StringBuffer();

  for (var k = 0; k < line.length; k++) {
    final ch = line[k];
    if (ch == '"') {
      if (inQuotes && k + 1 < line.length && line[k + 1] == '"') {
        current.write('"');
        k++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch == ',' && !inQuotes) {
      result.add(current.toString());
      current.clear();
    } else {
      current.write(ch);
    }
  }
  result.add(current.toString());
  return result;
}
