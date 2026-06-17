import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/tajweed_font_service.dart';
import '../providers/tajweed_page_provider.dart';

/// Renders a single ayah block (verseFrom..verseTo) with QCF V4 Tajweed COLR
/// colors for use inside the Surah screen.
///
/// Layout is identical to the normal surah screen (flowing RTL Wrap of words)
/// but glyphs come from the page-specific QCF V4 COLR font so Tajweed rule
/// colors are rendered correctly.
///
/// Falls back transparently to [fallback] while loading or on API failure.
class TajweedAyahWidget extends StatefulWidget {
  const TajweedAyahWidget({
    super.key,
    required this.surahId,
    required this.verseFrom,
    required this.verseTo,
    required this.fallback,
    this.fontSize = 22.0,
    this.textAlign = TextAlign.start,
    this.isDark = false,
  });

  final int surahId;
  final int verseFrom;
  final int verseTo;

  /// Widget shown while loading and as permanent fallback on API failure.
  final Widget fallback;

  final double fontSize;
  final TextAlign textAlign;
  final bool isDark;

  @override
  State<TajweedAyahWidget> createState() => _TajweedAyahWidgetState();
}

class _TajweedAyahWidgetState extends State<TajweedAyahWidget> {
  // Module-level cache shared across all instances. Key = "surahId:from:to".
  static final Map<String, List<TajweedPageWord>> _cache = {};

  final TajweedFontService _fontService = TajweedFontService.instance;

  List<TajweedPageWord>? _words;
  // page_number -> loaded font-family name
  final Map<int, String> _pageFamilies = {};
  bool _loading = true;
  bool _failed = false;

  String get _key =>
      '${widget.surahId}:${widget.verseFrom}:${widget.verseTo}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TajweedAyahWidget old) {
    super.didUpdateWidget(old);
    if (old.surahId != widget.surahId ||
        old.verseFrom != widget.verseFrom ||
        old.verseTo != widget.verseTo) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
      _words = null;
      _pageFamilies.clear();
    });

    try {
      // Use cache if available.
      final cached = _cache[_key];
      final List<TajweedPageWord> words;
      if (cached != null) {
        words = cached;
      } else {
        words = await _fetchWords();
        _cache[_key] = words;
      }

      if (!mounted) return;

      // Load Tajweed fonts for each unique page_number in this block.
      final pages =
          words.map((w) => w.pageNumber).where((p) => p > 0).toSet();
      for (final page in pages) {
        if (!_pageFamilies.containsKey(page)) {
          try {
            final family = await _fontService.ensurePageFont(page);
            if (mounted) _pageFamilies[page] = family;
          } catch (e) {
            log('TajweedAyahWidget: font load failed for page $page — $e');
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _words = words;
        _loading = false;
      });
    } catch (e) {
      log('TajweedAyahWidget: fetch failed for $_key — $e');
      if (mounted) setState(() { _loading = false; _failed = true; });
    }
  }

  Future<List<TajweedPageWord>> _fetchWords() async {
    final count = widget.verseTo - widget.verseFrom + 1;
    final uri = Uri.parse(
      'https://api.quran.com/api/v4/verses/by_chapter/${widget.surahId}'
      '?words=true'
      '&word_fields=code_v2,char_type_name,page_number'
      '&mushaf=19'
      '&from=${widget.verseFrom}'
      '&to=${widget.verseTo}'
      '&per_page=$count',
    );

    final resp =
        await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    final verses = data['verses'] as List<dynamic>? ?? [];

    final result = <TajweedPageWord>[];
    for (final verse in verses) {
      final v = verse as Map<String, dynamic>;
      final verseKey = (v['verse_key'] as String?) ?? '';
      final parts = verseKey.split(':');
      final surahId =
          parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final ayahId =
          parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

      final wWords = v['words'] as List<dynamic>? ?? [];
      for (final w in wWords) {
        result.add(TajweedPageWord.fromJson(
          w as Map<String, dynamic>,
          surahId: surahId,
          ayahId: ayahId,
        ));
      }
    }

    // Sort by (ayahId, position) — ayahs share a visual region and both
    // reset position to 1, so sorting by position alone would interleave them.
    result.sort((a, b) {
      final byAyah = a.ayahId.compareTo(b.ayahId);
      return byAyah != 0 ? byAyah : a.position.compareTo(b.position);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    // While loading or on failure, show the normal Arabic text unchanged.
    if (_loading || _failed || _words == null || _words!.isEmpty) {
      return widget.fallback;
    }

    final spans = <InlineSpan>[];
    for (final word in _words!) {
      if (word.codeV2.isEmpty) continue;

      final family = word.pageNumber > 0
          ? _pageFamilies[word.pageNumber]
          : null;

      spans.add(TextSpan(
        text: word.codeV2,
        style: TextStyle(
          fontFamily: family,
          fontSize: widget.fontSize,
          height: 1.6,
          color: widget.isDark ? null : Colors.black,
        ),
      ));
    }

    if (spans.isEmpty) return widget.fallback;

    Widget text = Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: widget.textAlign,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );

    // Dark mode: COLR fonts always paint with dark ink — wrap in a warm card.
    if (widget.isDark) {
      text = DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E8),
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: text,
        ),
      );
    }

    return text;
  }
}
