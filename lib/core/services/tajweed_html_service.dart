import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

final RegExp _leadingBasmalaHtmlRegex = RegExp(
  r'^\s*'
  r'ب[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'س[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'م[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*\s+'
  r'[اٱ][\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ل[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ل[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ه[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*\s+'
  r'[اٱ][\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ل[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ر[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ح[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'م[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ن[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*\s+'
  r'[اٱ][\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ل[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ر[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ح[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'[يیى][\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'م[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'(?:\s+|(?=<tajweed class=))',
);

final RegExp _leadingTajweedInnerSpaceRegex = RegExp(
  r'^(<tajweed class=[a-z_]+>)\s+',
);

String _stripLeadingBasmalaHtml(String html) {
  final stripped = html.replaceFirst(_leadingBasmalaHtmlRegex, '');
  if (stripped == html) return html;
  return stripped.replaceFirst(_leadingTajweedInnerSpaceRegex, r'$1');
}

/// Fetches the colour-coded Tajweed data (quran.com style) from the backend and
/// exposes a `verseKey -> text_tajweed_html` lookup plus a parser that turns
/// that HTML into coloured [InlineSpan]s.
///
/// The whole book is ~5.5 MB, so it is loaded a surah at a time and cached for
/// the app lifetime. Call [loadSurahs] before reading, then use the synchronous
/// [htmlFor] / [displayHtmlFor] while building.
///
/// This is a temporary, font/colour based replacement for the image-download
/// based Tajweed renderer.
class TajweedHtmlService {
  TajweedHtmlService._();

  // verseKey ("surah:ayah") -> text_tajweed_html
  static final Map<String, String> _verseHtml = {};
  static final Set<int> _loaded = {};
  static final Map<int, Future<void>> _inFlight = {};

  /// Fetches any of [surahs] not already cached. Safe to call repeatedly; a
  /// surah is only requested once even if several widgets ask at the same time.
  static Future<void> loadSurahs(Iterable<int> surahs) {
    final pending = surahs.toSet()
      ..removeWhere((surah) => _loaded.contains(surah) || surah <= 0);
    if (pending.isEmpty) return Future<void>.value();
    return Future.wait(pending.map(_loadSurah));
  }

  static Future<void> _loadSurah(int surah) {
    final existing = _inFlight[surah];
    if (existing != null) return existing;

    final future = _fetchSurah(surah);
    _inFlight[surah] = future;
    return future;
  }

  static Future<void> _fetchSurah(int surah) async {
    try {
      final rows = await MoqApiClient.instance.getList(
        '/tajweed/html',
        query: {'surah': surah},
      );
      for (final row in rows) {
        final key = row['verse_key'];
        final html = row['text_tajweed_html'];
        if (key is String && html is String) _verseHtml[key] = html;
      }
      if (rows.isNotEmpty) _loaded.add(surah);
    } finally {
      _inFlight.remove(surah);
    }
  }

  /// Returns the raw Tajweed HTML for a verse, or null if not loaded/missing.
  static String? htmlFor(int surah, int ayah) => _verseHtml['$surah:$ayah'];

  /// Like [htmlFor], but for the first verse of a surah it strips the leading
  /// Basmala so it is not shown twice alongside the decorative Bismillah header.
  /// Surah 1 (Basmala is verse 1:1) and surah 9 (no Basmala) are left untouched.
  static String? displayHtmlFor(int surah, int ayah) {
    final html = htmlFor(surah, ayah);
    if (html == null) return null;
    if (surah == 1 || surah == 9 || ayah != 1) return html;
    return _stripLeadingBasmalaHtml(html);
  }
}

/// quran.com colour scheme for each Tajweed rule, mirroring
/// `assets/db/quran_tajweed_data/output/tajweed-colors.css`.
const Map<String, Color> kTajweedRuleColors = {
  'ham_wasl': Color(0xFFAAAAAA),
  'laam_shamsiyah': Color(0xFFAAAAAA),
  'silent': Color(0xFFAAAAAA),
  'madda_normal': Color(0xFF537FFF),
  'madda_permissible': Color(0xFF4050FF),
  'madda_necessary': Color(0xFF000FB3),
  'madda_obligatory': Color(0xFF2144C1),
  'qalaqala': Color(0xFFDD0008),
  'ikhpiaa_shafawi': Color(0xFFD500B7),
  'ikhpiaa': Color(0xFF9400A8),
  'iqlab': Color(0xFF26BFFD),
  'idghaam_shafawi': Color(0xFF58B800),
  'idghaam_ghunnah': Color(0xFF169200),
  'idghaam_wo_ghunnah': Color(0xFF169200),
  'idghaam_mutajanisayn': Color(0xFFA1A1A1),
  'idghaam_mutaqaribayn': Color(0xFFA1A1A1),
  'ghunnah': Color(0xFFFF7E1E),
};

final RegExp _tajweedTagRegex = RegExp(
  r'<tajweed class=([a-z_]+)>(.*?)</tajweed>',
  dotAll: true,
);

/// Parses `<tajweed class=rule>...</tajweed>` HTML into coloured [InlineSpan]s.
/// Plain text outside any tag keeps [baseStyle]; tagged runs get the rule
/// colour from [kTajweedRuleColors].
List<InlineSpan> parseTajweedHtml(String html, TextStyle baseStyle) {
  final spans = <InlineSpan>[];
  var pos = 0;
  for (final match in _tajweedTagRegex.allMatches(html)) {
    if (match.start > pos) {
      spans.add(TextSpan(text: html.substring(pos, match.start), style: baseStyle));
    }
    final rule = match.group(1)!;
    final inner = match.group(2)!;
    final color = kTajweedRuleColors[rule];
    spans.add(
      TextSpan(
        text: inner,
        style: color != null ? baseStyle.copyWith(color: color) : baseStyle,
      ),
    );
    pos = match.end;
  }
  if (pos < html.length) {
    spans.add(TextSpan(text: html.substring(pos), style: baseStyle));
  }
  return spans;
}
