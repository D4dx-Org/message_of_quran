import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads the bundled colour-coded Tajweed data (quran.com style) and exposes a
/// `verseKey -> text_tajweed_html` lookup plus a parser that turns that HTML
/// into coloured [InlineSpan]s.
///
/// This is a temporary, font/colour based replacement for the image-download
/// based Tajweed renderer.
class TajweedHtmlService {
  TajweedHtmlService._();

  static const _assetPath =
      'assets/db/quran_tajweed_data/output/quran_tajweed_complete.json';

  // verseKey ("surah:ayah") -> text_tajweed_html
  static Map<String, String>? _verseHtml;
  static Future<void>? _loading;

  /// Ensures the JSON asset is parsed once and cached for the app lifetime.
  static Future<void> ensureLoaded() {
    if (_verseHtml != null) return Future<void>.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final map = <String, String>{};
    for (final value in decoded.values) {
      if (value is! Map<String, dynamic>) continue;
      final verses = value['verses'];
      if (verses is! List) continue;
      for (final v in verses) {
        if (v is! Map<String, dynamic>) continue;
        final key = v['verse_key'];
        final html = v['text_tajweed_html'];
        if (key is String && html is String) {
          map[key] = html;
        }
      }
    }
    _verseHtml = map;
  }

  /// Returns the raw Tajweed HTML for a verse, or null if not loaded/missing.
  static String? htmlFor(int surah, int ayah) => _verseHtml?['$surah:$ayah'];
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
