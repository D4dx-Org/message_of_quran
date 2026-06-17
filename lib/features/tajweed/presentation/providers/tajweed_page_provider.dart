import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../../../mushaf/data/mushaf_repository.dart';
import '../../../mushaf/models/mushaf_line.dart';
import '../../../mushaf/models/page_meta.dart';

/// A single Quran.com word for the Tajweed renderer.
class TajweedPageWord {
  const TajweedPageWord({
    required this.surahId,
    required this.ayahId,
    required this.position,
    required this.lineNumber,
    required this.pageNumber,
    required this.charTypeName,
    required this.codeV2,
    required this.textQpcHafs,
  });

  final int surahId;
  final int ayahId;
  final int position;
  final int lineNumber;
  final int pageNumber;
  final String charTypeName;
  final String codeV2;
  final String textQpcHafs;

  factory TajweedPageWord.fromJson(Map<String, dynamic> json,
      {required int surahId, required int ayahId}) {
    return TajweedPageWord(
      surahId: surahId,
      ayahId: ayahId,
      position: (json['position'] as num?)?.toInt() ?? 0,
      lineNumber: (json['line_number'] as num?)?.toInt() ?? 0,
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 0,
      charTypeName: (json['char_type_name'] as String?) ?? '',
      codeV2: (json['code_v2'] as String?) ?? '',
      textQpcHafs: (json['text_qpc_hafs'] as String?) ?? '',
    );
  }
}

/// Combined page data used by [TajweedPageView].
class TajweedPageData {
  const TajweedPageData({
    required this.pageNo,
    required this.lines,
    required this.meta,
    required this.suraGlyph,
    required this.wordLinesByVisualLine,
    required this.apiAvailable,
  });

  final int pageNo;
  final List<MushafLine> lines;
  final PageMeta? meta;
  final String suraGlyph;

  /// API word data grouped by visual line number.
  /// Empty if the API request failed (fall back to local DB lines).
  final Map<int, List<TajweedPageWord>> wordLinesByVisualLine;

  final bool apiAvailable;
}

/// Loads a single page's local structure and Quran.com word-level Tajweed data.
class TajweedPageProvider {
  TajweedPageProvider({MushafRepository? repository})
      : _repository = repository ?? MushafRepository();

  final MushafRepository _repository;

  static const String _apiBase = 'https://api.quran.com/api/v4';
  static const String _wordFields =
      'code_v2,text_qpc_hafs,char_type_name,line_number,page_number';

  /// Fetches all data needed to render [pageNo].
  ///
  /// If the Quran.com API fails, [TajweedPageData.apiAvailable] will be
  /// `false` and [TajweedPageData.wordLinesByVisualLine] will be empty.
  Future<TajweedPageData> fetchPage(int pageNo) async {
    // Load local data in parallel with the API request.
    final localFuture = _loadLocalData(pageNo);
    final apiFuture = _fetchApiWords(pageNo);

    final local = await localFuture;
    final apiResult = await apiFuture;

    return TajweedPageData(
      pageNo: pageNo,
      lines: local.lines,
      meta: local.meta,
      suraGlyph: local.suraGlyph,
      wordLinesByVisualLine: apiResult.words,
      apiAvailable: apiResult.ok,
    );
  }

  Future<_LocalPageData> _loadLocalData(int pageNo) async {
    final results = await Future.wait([
      _repository.getMushafPageLines(pageNo),
      _repository.getPageMeta(pageNo),
    ]);

    final lines = results[0] as List<MushafLine>;
    final meta = results[1] as PageMeta?;

    String suraGlyph = '';
    if (meta != null) {
      suraGlyph = await _repository.getSuraNameGlyph(meta.suraNo);
    }

    return _LocalPageData(lines: lines, meta: meta, suraGlyph: suraGlyph);
  }

  Future<_ApiResult> _fetchApiWords(int pageNo) async {
    try {
      final uri = Uri.parse(
        '$_apiBase/verses/by_page/$pageNo'
        '?words=true'
        '&word_fields=$_wordFields'
        '&mushaf=19'
        '&per_page=50'
        '&page=1',
      );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final verses = decoded['verses'] as List<dynamic>? ?? [];

      // Check if the response has pagination and fetch all pages.
      final pagination = decoded['pagination'] as Map<String, dynamic>?;
      final totalPages = (pagination?['total_pages'] as num?)?.toInt() ?? 1;

      var allVerses = List<dynamic>.from(verses);

      for (var p = 2; p <= totalPages; p++) {
        final nextUri = Uri.parse(
          '$_apiBase/verses/by_page/$pageNo'
          '?words=true'
          '&word_fields=$_wordFields'
          '&mushaf=19'
          '&per_page=50'
          '&page=$p',
        );
        final nextResponse =
            await http.get(nextUri).timeout(const Duration(seconds: 10));
        if (nextResponse.statusCode == 200) {
          final nextDecoded =
              json.decode(nextResponse.body) as Map<String, dynamic>;
          final nextVerses = nextDecoded['verses'] as List<dynamic>? ?? [];
          allVerses.addAll(nextVerses);
        }
      }

      final wordMap = <int, List<TajweedPageWord>>{};

      for (final verse in allVerses) {
        final v = verse as Map<String, dynamic>;
        final verseKey = (v['verse_key'] as String?) ?? '';
        final parts = verseKey.split(':');
        final surahId = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
        final ayahId = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

        final words = v['words'] as List<dynamic>? ?? [];
        for (final w in words) {
          final word = TajweedPageWord.fromJson(
            w as Map<String, dynamic>,
            surahId: surahId,
            ayahId: ayahId,
          );
          if (word.lineNumber > 0) {
            wordMap.putIfAbsent(word.lineNumber, () => []).add(word);
          }
        }
      }

      log('TajweedPageProvider: page $pageNo loaded ${allVerses.length} verses '
          'from API (${wordMap.length} lines)');
      return _ApiResult(words: wordMap, ok: true);
    } catch (e) {
      log('TajweedPageProvider: API failed for page $pageNo — $e');
      return const _ApiResult(words: {}, ok: false);
    }
  }
}

class _LocalPageData {
  const _LocalPageData({
    required this.lines,
    required this.meta,
    required this.suraGlyph,
  });
  final List<MushafLine> lines;
  final PageMeta? meta;
  final String suraGlyph;
}

class _ApiResult {
  const _ApiResult({required this.words, required this.ok});
  final Map<int, List<TajweedPageWord>> words;
  final bool ok;
}
