import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

import '../models/mushaf_line.dart';
import '../models/page_meta.dart';

/// Mushaf-only data access layer, backed by the MOQ REST API.
class MushafRepository {
  Future<List<MushafLine>> getMushafPageLines(int pageNo) async {
    final rows = await MoqApiClient.instance.getList(
      '/mushaf/pages/$pageNo/lines',
    );
    return rows.map(MushafLine.fromMap).toList(growable: false);
  }

  Future<PageMeta?> getPageMeta(int pageNo) async {
    final row = await MoqApiClient.instance.getObject(
      '/mushaf/pages/$pageNo/meta',
    );
    if (row == null) return null;
    return PageMeta.fromMap(row);
  }

  /// Returns the actual ayas (continuous id + sura/aya number) that belong to a
  /// page, given the page's [startAya]/[endAya] continuous-id range. Used by the
  /// Tajweed reading mode to render colour-coded plain Arabic per page.
  Future<List<({int ayaId, int suraNo, int ayaNo})>> getPageAyas(
    int startAya,
    int endAya,
  ) async {
    if (startAya <= 0 || endAya < startAya) return const [];
    final rows = await MoqApiClient.instance.getList(
      '/mushaf/pages/ayas',
      query: {'start': startAya, 'end': endAya},
    );
    return rows
        .map((r) => (
              ayaId: (r['aya_id'] as num).toInt(),
              suraNo: (r['s_no'] as num).toInt(),
              ayaNo: (r['aya_no'] as num).toInt(),
            ))
        .toList(growable: false);
  }

  Future<String> getSuraNameGlyph(int suraNo) async {
    final row = await MoqApiClient.instance.getObject(
      '/mushaf/surahs/$suraNo/glyph',
    );
    if (row == null) return '';
    return (row['data'] as String?) ?? '';
  }

  Future<String> getBismillahGlyph(int suraNo) async {
    final row = await MoqApiClient.instance.getObject(
      '/mushaf/surahs/$suraNo/bismillah-glyph',
    );
    if (row == null) return '';
    return (row['data'] as String?) ?? '';
  }

  Future<String> getJuzName(int juzNo) async {
    final row = await MoqApiClient.instance.getObject(
      '/mushaf/juzs/$juzNo/name',
    );
    if (row == null) return '';
    return (row['name'] as String?) ?? '';
  }

  Future<int> getPageForAya(int continuesAyaId) async {
    if (continuesAyaId <= 0) return 0;
    final row = await MoqApiClient.instance.getObject(
      '/mushaf/ayas/$continuesAyaId/page',
    );
    if (row == null || row['page'] == null) return 0;
    return (row['page'] as num).toInt();
  }

  Future<int> getContinuesAyaId(int suraId, int ayaNo) async {
    final row = await MoqApiClient.instance.getObject(
      '/mushaf/ayas/continuous-id',
      query: {'surah': suraId, 'aya': ayaNo},
    );
    if (row == null || row['ayaId'] == null) return 0;
    return (row['ayaId'] as num).toInt();
  }

  Future<int> getFirstPageForSurah(int suraNo) async {
    final row = await MoqApiClient.instance.getObject(
      '/mushaf/surahs/$suraNo/first-page',
    );
    if (row == null || row['page'] == null) return 1;
    return (row['page'] as num).toInt();
  }

  Future<List<({int juzNo, int firstPage})>> getAllJuzFirstPages() async {
    final rows = await MoqApiClient.instance.getList(
      '/mushaf/juzs/first-pages',
    );
    return rows
        .map((r) => (
              juzNo: (r['j_no'] as num).toInt(),
              firstPage: (r['first_page'] as num).toInt(),
            ))
        .toList();
  }

  Future<List<int>> getContinuousAyaIdsForSurah(int suraNo) async {
    return MoqApiClient.instance.getIntList(
      '/mushaf/surahs/$suraNo/continuous-aya-ids',
    );
  }

  Future<({int suraNo, int ayaNo})> getAyaInfo(int continuousAyaId) async {
    final row = await MoqApiClient.instance.getObject(
      '/mushaf/ayas/$continuousAyaId/info',
    );
    if (row == null) return (suraNo: 1, ayaNo: 1);
    return (
      suraNo: (row['suraNo'] as num).toInt(),
      ayaNo: (row['ayaNo'] as num).toInt(),
    );
  }

  Future<List<PageMeta?>> getAllPageMetas() async {
    final rows = await MoqApiClient.instance.getList('/mushaf/pages/meta');
    final result = List<PageMeta?>.filled(604, null);
    for (final row in rows) {
      final meta = PageMeta.fromMap(row);
      final idx = meta.pageNo - 1;
      if (idx >= 0 && idx < 604) result[idx] = meta;
    }
    return result;
  }

  Future<Map<int, String>> getAllSurahGlyphs() async {
    final rows = await MoqApiClient.instance.getList('/mushaf/surahs/glyphs');
    return {
      for (final r in rows)
        (r['suraid'] as num).toInt(): (r['data'] as String?) ?? '',
    };
  }

  Future<Map<int, String>> getAllBismillahGlyphs() async {
    final rows = await MoqApiClient.instance.getList(
      '/mushaf/bismillah-glyphs',
    );
    return {
      for (final r in rows)
        (r['suraid'] as num).toInt(): (r['data'] as String?) ?? '',
    };
  }
}
