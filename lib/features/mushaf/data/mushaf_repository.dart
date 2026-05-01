import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../db/local_database.dart';
import '../models/mushaf_line.dart';
import '../models/page_meta.dart';

/// Mushaf-only database access layer.
class MushafRepository {
  MushafRepository({LocalDatabase? localDatabase})
      : _localDatabase = localDatabase ?? LocalDatabase.instance;

  final LocalDatabase _localDatabase;

  Future<Database> get _db async => _localDatabase.database;

  Future<List<MushafLine>> getMushafPageLines(int pageNo) async {
    final rows = await (await _db).rawQuery(
      'SELECT * FROM t_mushafpages WHERE pageid=? ORDER BY id',
      [pageNo],
    );
    return rows.map(MushafLine.fromMap).toList(growable: false);
  }

  Future<PageMeta?> getPageMeta(int pageNo) async {
    final rows = await (await _db).rawQuery(
      'SELECT * FROM t_ayawise_page WHERE p_id=?',
      [pageNo],
    );
    if (rows.isEmpty) return null;
    return PageMeta.fromMap(rows.first);
  }

  Future<String> getSuraNameGlyph(int suraNo) async {
    final rows = await (await _db).rawQuery(
      'SELECT data FROM t_mushafpages WHERE suraid=? AND line=-1 LIMIT 1',
      [suraNo],
    );
    if (rows.isEmpty) return '';
    return (rows.first['data'] as String?) ?? '';
  }

  Future<String> getBismillahGlyph(int suraNo) async {
    final rows = await (await _db).rawQuery(
      'SELECT data FROM t_mushafpages WHERE suraid=? AND line=0 LIMIT 1',
      [suraNo],
    );
    if (rows.isEmpty) return '';
    return (rows.first['data'] as String?) ?? '';
  }

  Future<String> getJuzName(int juzNo) async {
    try {
      final rows = await (await _db).rawQuery(
        'SELECT j_name FROM t_juznames WHERE j_no=?',
        [juzNo],
      );
      if (rows.isEmpty) return '';
      return (rows.first['j_name'] as String?) ?? '';
    } catch (e) {
      debugPrint('MushafRepo: getJuzName failed — $e');
      return '';
    }
  }

  Future<int> getPageForAya(int continuesAyaId) async {
    if (continuesAyaId <= 0) return 0;
    final rows = await (await _db).rawQuery(
      'SELECT p_id FROM t_ayawise_page WHERE s_aya<=? AND e_aya>=? LIMIT 1',
      [continuesAyaId, continuesAyaId],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['p_id'] as num).toInt();
  }

  Future<int> getContinuesAyaId(int suraId, int ayaNo) async {
    final rows = await (await _db).rawQuery(
      'SELECT aya_id FROM t_aya WHERE s_no=? AND aya_no=? LIMIT 1',
      [suraId, ayaNo],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['aya_id'] as num).toInt();
  }

  Future<int> getFirstPageForSurah(int suraNo) async {
    final rows = await (await _db).rawQuery(
      'SELECT MIN(p.p_id) AS first_page '
      'FROM t_ayawise_page p '
      'JOIN t_aya a ON a.aya_id BETWEEN p.s_aya AND p.e_aya '
      'WHERE a.s_no=? AND a.aya_no>0',
      [suraNo],
    );
    if (rows.isEmpty || rows.first['first_page'] == null) return 1;
    return (rows.first['first_page'] as num).toInt();
  }

  Future<List<({int juzNo, int firstPage})>> getAllJuzFirstPages() async {
    final rows = await (await _db).rawQuery(
      'SELECT j_no, MIN(p_id) AS first_page FROM t_ayawise_page GROUP BY j_no ORDER BY j_no',
    );
    return rows
        .map((r) => (
              juzNo: (r['j_no'] as num).toInt(),
              firstPage: (r['first_page'] as num).toInt(),
            ))
        .toList();
  }

  Future<List<int>> getContinuousAyaIdsForSurah(int suraNo) async {
    final rows = await (await _db).rawQuery(
      'SELECT aya_id FROM t_aya WHERE s_no=? AND aya_no > 0 ORDER BY aya_no',
      [suraNo],
    );
    return rows.map((r) => (r['aya_id'] as num).toInt()).toList();
  }

  Future<({int suraNo, int ayaNo})> getAyaInfo(int continuousAyaId) async {
    final rows = await (await _db).rawQuery(
      'SELECT s_no, aya_no FROM t_aya WHERE aya_id=? LIMIT 1',
      [continuousAyaId],
    );
    if (rows.isEmpty) return (suraNo: 1, ayaNo: 1);
    return (
      suraNo: (rows.first['s_no'] as num).toInt(),
      ayaNo: (rows.first['aya_no'] as num).toInt(),
    );
  }

  Future<List<PageMeta?>> getAllPageMetas() async {
    final rows = await (await _db).rawQuery(
      'SELECT * FROM t_ayawise_page ORDER BY p_id',
    );
    final result = List<PageMeta?>.filled(604, null);
    for (final row in rows) {
      final meta = PageMeta.fromMap(row);
      final idx = meta.pageNo - 1;
      if (idx >= 0 && idx < 604) result[idx] = meta;
    }
    return result;
  }

  Future<Map<int, String>> getAllSurahGlyphs() async {
    try {
      final rows = await (await _db).rawQuery(
        'SELECT suraid, data FROM t_mushafpages WHERE line=-1 GROUP BY suraid ORDER BY suraid',
      );
      return {
        for (final r in rows)
          (r['suraid'] as num).toInt(): (r['data'] as String?) ?? '',
      };
    } catch (e) {
      debugPrint('MushafRepo: getAllSurahGlyphs failed — $e');
      return {};
    }
  }

  Future<Map<int, String>> getAllBismillahGlyphs() async {
    try {
      final rows = await (await _db).rawQuery(
        'SELECT suraid, data FROM t_mushafpages WHERE line=0 GROUP BY suraid ORDER BY suraid',
      );
      return {
        for (final r in rows)
          (r['suraid'] as num).toInt(): (r['data'] as String?) ?? '',
      };
    } catch (e) {
      debugPrint('MushafRepo: getAllBismillahGlyphs failed — $e');
      return {};
    }
  }
}
