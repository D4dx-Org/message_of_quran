import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/mushaf/services/qcf_font_service.dart';
import '../../../../features/mushaf/utils/mushaf_text_utils.dart';
import '../../../../features/mushaf/models/mushaf_line.dart';
import '../../../../features/mushaf/data/mushaf_repository.dart';
import '../../../../core/widgets/pinch_zoom_view.dart';
import '../../../../features/settings_screen/providers/tajweed_provider.dart';
import '../../services/tajweed_font_service.dart';
import '../providers/tajweed_page_provider.dart';

const _kSurahHeader = 'assets/images/mushaf-title.png';

/// V2 byte range covered by the V4 Tajweed pack.
const int _v4CoveredMin = 0x21;
const int _v4CoveredMax = 0xAE;
const int _v4Offset = 0xFC20;

/// Renders a single Mushaf page using the QCF V4 Tajweed COLR fonts.
///
/// - Uses [TajweedFontService] to load the per-page Tajweed font.
/// - Fetches Quran.com word data via [TajweedPageProvider].
/// - Falls back to local DB line rendering when the API is unavailable.
/// - Uses the existing [QcfFontService] as a V2 fallback for uncovered glyphs.
class TajweedPageView extends StatefulWidget {
  const TajweedPageView({
    super.key,
    required this.pageNo,
    required this.repository,
    this.selectedAyaId,
    this.playingAyaId,
    this.onAyaTap,
    this.actionRow,
    this.quranFontSize = 24.0,
  });

  final int pageNo;
  final MushafRepository repository;
  final int? selectedAyaId;
  final int? playingAyaId;
  final VoidCallback? onAyaTap;
  final Widget? actionRow;
  final double quranFontSize;

  @override
  State<TajweedPageView> createState() => _TajweedPageViewState();
}

class _TajweedPageViewState extends State<TajweedPageView> {
  final TajweedFontService _tajweedFontService = TajweedFontService.instance;
  final QcfFontService _v2FontService = QcfFontService.instance;
  final ValueNotifier<int> _rebuild = ValueNotifier<int>(0);

  TajweedPageData? _pageData;
  String? _tajweedFamily;
  String? _bsmlFamily;
  String? _v2Family; // fallback for bytes > 0xAE
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _rebuild.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TajweedPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNo != widget.pageNo) _loadData();
  }

  Future<void> _loadData() async {
    _loading = true;
    _error = null;
    _rebuild.value++;

    try {
      // Load page data + Tajweed font in parallel.
      final provider = TajweedPageProvider(repository: widget.repository);
      final results = await Future.wait([
        provider.fetchPage(widget.pageNo),
        _tajweedFontService.ensurePageFont(widget.pageNo),
        _v2FontService.ensureBsmlFont(),
      ]);

      if (!mounted) return;

      _pageData = results[0] as TajweedPageData;
      _tajweedFamily = results[1] as String;
      _bsmlFamily = results[2] as String;

      // Load V2 fallback font (best effort – failures are non-fatal).
      unawaited(_loadV2Fallback(widget.pageNo));

      _loading = false;
      _rebuild.value++;

      _tajweedFontService.preloadAdjacent(widget.pageNo);
    } on TajweedFontNotInstalledError {
      if (!mounted) return;
      _loading = false;
      _error = 'tajweed_not_installed';
      _rebuild.value++;
    } catch (e) {
      if (!mounted) return;
      _loading = false;
      _error = e.toString();
      _rebuild.value++;
    }
  }

  Future<void> _loadV2Fallback(int pageNo) async {
    try {
      final family = await _v2FontService.ensurePageFont(pageNo);
      if (!mounted) return;
      _v2Family = family;
      _rebuild.value++;
    } catch (_) {
      // V2 fallback is optional.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _rebuild,
      builder: (context, _, child) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error == 'tajweed_not_installed') {
      return _buildNotInstalledState(context);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      );
    }

    final data = _pageData;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildPage(context, data);
  }

  Widget _buildNotInstalledState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Tajweed fonts are not installed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to Settings → Tajweed to download the font pack.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Consumer<TajweedProvider>(
              builder: (ctx, tajweed, _) => ElevatedButton(
                onPressed: tajweed.isDownloading ? null : () => tajweed.startDownload(),
                child: tajweed.isDownloading
                    ? Text('Downloading ${(tajweed.downloadProgress * 100).toStringAsFixed(0)}%')
                    : const Text('Download Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, TajweedPageData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isFirstTwoPages = widget.pageNo == 1 || widget.pageNo == 2;
    final lineCount = data.lines.length;
    final isSpecialPage = lineCount == 8;

    double baseFontSize = widget.quranFontSize;
    if (isSpecialPage) baseFontSize *= 1.15;

    const double lineHeight = 1.6;
    final headSize = baseFontSize * 0.85;

    final List<Widget> topWidgets = [];
    final List<Widget> lineWidgets = [];

    if (isSpecialPage) lineWidgets.add(const SizedBox(height: 8));

    final useApiLines =
        data.apiAvailable && data.wordLinesByVisualLine.isNotEmpty;

    if (useApiLines) {
      _buildApiLines(
        context,
        data,
        lineWidgets,
        topWidgets,
        isDark,
        textColor,
        baseFontSize,
        headSize,
        lineHeight,
        isFirstTwoPages,
      );
    } else {
      _buildDbLines(
        context,
        data,
        lineWidgets,
        topWidgets,
        isDark,
        textColor,
        baseFontSize,
        headSize,
        lineHeight,
        isFirstTwoPages,
      );
    }

    if (isSpecialPage) lineWidgets.add(const SizedBox(height: 8));

    return GestureDetector(
      onTap: () => widget.onAyaTap?.call(),
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            children: [
              if (!isSpecialPage)
                _buildPageHeader(data, headSize, textColor),
              if (!isLandscape && isFirstTwoPages)
                const SizedBox(height: kToolbarHeight),
              if (!isLandscape && isFirstTwoPages) ...topWidgets,
              Expanded(
                child: PinchZoomView(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLandscape && isFirstTwoPages)
                              const SizedBox(height: kToolbarHeight),
                            if (isLandscape && isFirstTwoPages) ...topWidgets,
                            ...lineWidgets,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!isFirstTwoPages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${widget.pageNo}',
                    style: TextStyle(
                      fontSize: baseFontSize * 0.55,
                      color: textColor.withValues(alpha: 0.45),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── API-word rendering ─────────────────────────────────────────────

  void _buildApiLines(
    BuildContext context,
    TajweedPageData data,
    List<Widget> lineWidgets,
    List<Widget> topWidgets,
    bool isDark,
    Color textColor,
    double fontSize,
    double headSize,
    double lineHeight,
    bool isFirstTwoPages,
  ) {
    // Group unique visual line numbers from the API.
    final lineNos = data.wordLinesByVisualLine.keys.toList()..sort();

    // We still need to render surah headings and bismillah from local DB lines.
    for (final line in data.lines) {
      if (line.lineId == -1) {
        final heading = _buildSuraHeading(line, headSize, textColor);
        if (isFirstTwoPages) {
          topWidgets.add(heading);
        } else {
          lineWidgets.add(heading);
        }
      } else if (line.lineId == 0) {
        lineWidgets.add(_buildBismillahLine(line, headSize, textColor));
      }
    }

    // Render each API word-line.
    for (final lineNo in lineNos) {
      final words = data.wordLinesByVisualLine[lineNo]!;
      lineWidgets.add(
        _buildApiWordLine(words, fontSize, lineHeight, isDark, textColor),
      );
    }
  }

  Widget _buildApiWordLine(
    List<TajweedPageWord> words,
    double fontSize,
    double lineHeight,
    bool isDark,
    Color textColor,
  ) {
    final spans = <InlineSpan>[];

    for (final word in words) {
      if (word.codeV2.isEmpty) continue;

      final (glyphText, families) = _resolveWordGlyph(word.codeV2);

      final style = TextStyle(
        fontFamily: families.isNotEmpty ? families.first : _tajweedFamily,
        fontFamilyFallback: families.length > 1 ? families.sublist(1) : null,
        fontSize: fontSize,
        height: lineHeight,
        // Dark mode: use a warm card background color matrix effect via
        // ColorFilter is not directly available on Text; we rely on the
        // COLR font's own palette. For dark mode, wrap in a light card.
        color: isDark ? null : textColor,
      );

      spans.add(TextSpan(text: glyphText, style: style));
    }

    if (spans.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (ctx, constraints) => SizedBox(
        width: constraints.maxWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: _wrapForDark(
            isDark,
            Text.rich(
              TextSpan(children: spans),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ── DB-line fallback rendering ─────────────────────────────────────

  void _buildDbLines(
    BuildContext context,
    TajweedPageData data,
    List<Widget> lineWidgets,
    List<Widget> topWidgets,
    bool isDark,
    Color textColor,
    double fontSize,
    double headSize,
    double lineHeight,
    bool isFirstTwoPages,
  ) {
    for (final line in data.lines) {
      if (line.lineId == -1) {
        final heading = _buildSuraHeading(line, headSize, textColor);
        if (isFirstTwoPages) {
          topWidgets.add(heading);
        } else {
          lineWidgets.add(heading);
        }
      } else if (line.lineId == 0) {
        lineWidgets.add(_buildBismillahLine(line, headSize, textColor));
      } else {
        lineWidgets.add(
          _buildDbAyaLine(line, fontSize, lineHeight, isDark, textColor),
        );
      }
    }
  }

  Widget _buildDbAyaLine(
    MushafLine line,
    double fontSize,
    double lineHeight,
    bool isDark,
    Color textColor,
  ) {
    final rawData = line.data;
    final parts = rawData.split('▌');
    final segmentTexts = <String>[];
    var firstVisible = true;
    for (final part in parts) {
      final reversed =
          MushafTextUtils.reverseText(part.replaceAll('▼', ''))
              .replaceAll('▌', '')
              .trim();
      if (reversed.isEmpty) continue;
      segmentTexts.add(firstVisible ? '$reversed\u0020' : reversed);
      firstVisible = false;
    }

    final spans = <InlineSpan>[];
    for (final seg in segmentTexts) {
      final converted = _convertDbTextForV4(seg);
      final (glyphText, families) = _resolveGlyphFromBytes(converted);
      final style = TextStyle(
        fontFamily: families.isNotEmpty ? families.first : _tajweedFamily,
        fontFamilyFallback: families.length > 1 ? families.sublist(1) : null,
        fontSize: fontSize,
        height: lineHeight,
        color: isDark ? null : textColor,
      );
      // LRO/PDF markers preserve visual glyph order.
      spans.add(TextSpan(
        text: '\u202D$glyphText\u202C',
        style: style,
      ));
    }

    if (spans.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (ctx, constraints) => SizedBox(
        width: constraints.maxWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: _wrapForDark(
            isDark,
            Text.rich(
              TextSpan(children: spans),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
      ),
    );
  }

  // ── Glyph resolution helpers ──────────────────────────────────────

  /// Converts a raw DB text segment to V4-mapped code-points where covered,
  /// keeping uncovered bytes as-is (for V2 fallback font).
  String _convertDbTextForV4(String rawSeg) {
    final codeUnits = <int>[];
    for (final byte in rawSeg.codeUnits) {
      if (byte >= _v4CoveredMin && byte <= _v4CoveredMax) {
        codeUnits.add(byte + _v4Offset);
      } else {
        codeUnits.add(byte);
      }
    }
    return String.fromCharCodes(codeUnits);
  }

  /// Splits a V4-converted segment into covered/uncovered chunks and returns
  /// the text and font-family list.
  (String, List<String>) _resolveGlyphFromBytes(String convertedSeg) {
    // Simplification: return the full string with Tajweed as primary,
    // V2 as fallback (Flutter will use the appropriate font per glyph).
    final families = <String>[
      if (_tajweedFamily != null) _tajweedFamily!,
      if (_v2Family != null) _v2Family!,
    ];
    return (convertedSeg, families);
  }

  /// Resolves glyph text and font families for a word from the API (code_v2
  /// is used directly as the glyph selector in the V4 Tajweed font).
  (String, List<String>) _resolveWordGlyph(String codeV2) {
    final families = <String>[
      if (_tajweedFamily != null) _tajweedFamily!,
      if (_v2Family != null) _v2Family!,
    ];
    return (codeV2, families);
  }

  // ── Dark-mode wrapper ─────────────────────────────────────────────

  /// For dark mode: wrap in a warm-parchment card so COLR base-ink (always
  /// black/dark) remains readable. COLR fonts' palette cannot be overridden
  /// via CSS `font-palette` in Flutter.
  Widget _wrapForDark(bool isDark, Widget child) {
    if (!isDark) return child;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F0E8),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: child,
      ),
    );
  }

  // ── Heading / bismillah builders ───────────────────────────────────

  Widget _buildSuraHeading(MushafLine line, double headSize, Color textColor) {
    final segments =
        MushafTextUtils.parseLine(line.data, isHeadingOrBismillah: true);
    final displayText = segments.isNotEmpty ? segments.first.text : '';
    final isPotrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: 2, horizontal: isPotrait ? 10 : 50),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              _kSurahHeader,
              height: isPotrait ? 56 : 70,
              width: double.infinity,
              fit: isPotrait ? BoxFit.contain : BoxFit.fill,
            ),
            Text(
              displayText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: _bsmlFamily,
                fontSize: headSize,
                height: 1.0,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBismillahLine(MushafLine line, double headSize, Color textColor) {
    final segments =
        MushafTextUtils.parseLine(line.data, isHeadingOrBismillah: true);
    final displayText = segments.isNotEmpty ? segments.first.text : '';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Center(
        child: Text(
          displayText,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontFamily: _bsmlFamily,
            fontSize: headSize,
            height: 1.4,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(
    TajweedPageData data,
    double headSize,
    Color textColor,
  ) {
    final suraGlyph = data.suraGlyph.isNotEmpty
        ? MushafTextUtils.reverseText(data.suraGlyph)
        : '';
    final juzNo = data.meta?.juzNo ?? 0;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final hSize = isLandscape ? headSize * 0.5 : headSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          if (juzNo > 0)
            Text(
              'Juz $juzNo',
              style: TextStyle(
                fontSize: hSize * 0.75,
                color: Colors.grey,
              ),
            ),
          const Spacer(),
          if (suraGlyph.isNotEmpty)
            Text(
              suraGlyph,
              style: TextStyle(
                fontFamily: _bsmlFamily,
                fontSize: hSize,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}
