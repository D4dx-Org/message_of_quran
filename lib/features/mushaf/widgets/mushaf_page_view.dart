import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mushaf_repository.dart';
import '../models/mushaf_line.dart';
import '../models/page_meta.dart';
import '../services/mushaf_download_manager.dart';
import '../services/qcf_font_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/services/tajweed_html_service.dart';
import '../../../core/widgets/pinch_zoom_view.dart';
import '../../settings_screen/providers/tajweed_provider.dart';
import '../utils/mushaf_text_utils.dart';

const _kSecondaryDarkColor = AppTheme.appIconTheme;
const _kSurahHeader = 'assets/images/mushaf-title.png';

/// Renders a single Mushaf page using QCF page fonts.
class MushafPageView extends StatefulWidget {
  const MushafPageView({
    super.key,
    required this.pageNo,
    required this.repository,
    this.beforeFirstAya,
    this.selectedAyaId,
    this.playingAyaId,
    this.onAyaTap,
    this.onAyaLongPress,
    this.onDismissSelection,
    this.actionRow,
    this.quranFontSize = 24.0,
  });

  final int pageNo;
  final MushafRepository repository;
  final Widget? beforeFirstAya;
  final int? selectedAyaId;
  final int? playingAyaId;
  final VoidCallback? onAyaTap;
  final void Function(int ayaId, int suraId)? onAyaLongPress;
  final VoidCallback? onDismissSelection;
  final Widget? actionRow;
  final double quranFontSize;

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  final QcfFontService _fontService = QcfFontService.instance;
  final ValueNotifier<int> _rebuild = ValueNotifier<int>(0);

  List<MushafLine>? _lines;
  PageMeta? _meta;
  String? _pageFontFamily;
  String? _bsmlFontFamily;
  String? _suraGlyph;
  bool _loading = true;
  String? _error;

  /// Ayas belonging to this page (continuous id + sura/aya number), used by the
  /// Tajweed reading mode to render colour-coded plain Arabic.
  List<({int ayaId, int suraNo, int ayaNo})> _pageAyas = const [];

  Color _textColor = Colors.black;
  Color _highlightColor = _kSecondaryDarkColor;
  Color _playingColor = _kSecondaryDarkColor;

  OverlayEntry? _tooltipOverlay;
  final LayerLink _tooltipLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _removeTooltipOverlay();
    _rebuild.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MushafPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNo != widget.pageNo) _loadData();
    if (widget.selectedAyaId == null && oldWidget.selectedAyaId != null) {
      _removeTooltipOverlay();
    }
  }

  Future<void> _loadData() async {
    _loading = true;
    _error = null;
    _rebuild.value++;

    try {
      final results = await Future.wait([
        _fontService.ensurePageFont(widget.pageNo),
        _fontService.ensureBsmlFont(),
        widget.repository.getMushafPageLines(widget.pageNo),
        widget.repository.getPageMeta(widget.pageNo),
      ]);

      if (!mounted) return;

      final meta = results[3] as PageMeta?;

      String suraGlyph = '';
      if (meta != null) {
        suraGlyph = await widget.repository.getSuraNameGlyph(meta.suraNo);
      }

      if (!mounted) return;

      _pageFontFamily = results[0] as String;
      _bsmlFontFamily = results[1] as String;
      _lines = results[2] as List<MushafLine>;
      _meta = meta;
      _suraGlyph = suraGlyph;
      _loading = false;
      _rebuild.value++;

      _fontService.preloadAdjacent(widget.pageNo);

      // Load the page's ayas + Tajweed data lazily so the colour-coded reading
      // mode is ready if the user has Tajweed enabled. Failures are non-fatal.
      if (meta != null) {
        unawaited(_loadTajweedData(meta));
      }
    } catch (e) {
      if (!mounted) return;
      _loading = false;
      _error = e.toString();
      _rebuild.value++;
    }
  }

  Future<void> _loadTajweedData(PageMeta meta) async {
    try {
      final results = await Future.wait([
        widget.repository.getPageAyas(meta.startAya, meta.endAya),
        TajweedHtmlService.ensureLoaded(),
      ]);
      if (!mounted) return;
      _pageAyas =
          results[0] as List<({int ayaId, int suraNo, int ayaNo})>;
      _rebuild.value++;
    } catch (_) {
      // Tajweed data is optional; ignore failures and fall back to QCF.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _rebuild,
      builder: (context, _, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _textColor = isDarkMode ? Colors.white : Colors.black;
    _highlightColor = _kSecondaryDarkColor;
    _playingColor = _kSecondaryDarkColor;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final dm = MushafDownloadManager.instance;
      final downloading = dm.isDownloading;
      final percent = (dm.progress * 100).toStringAsFixed(0);

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                downloading ? Icons.downloading_rounded : Icons.lock_outline,
                size: 48,
                color: _kSecondaryDarkColor,
              ),
              const SizedBox(height: 12),
              Text(
                downloading
                    ? 'Download in progress — $percent%'
                    : 'Page ${widget.pageNo} is not available offline.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (downloading) ...[
                const SizedBox(height: 8),
                const Text(
                  'This page will be available once the download completes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              if (!downloading) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final lines = _lines;
    if (lines == null || lines.isEmpty) {
      return Center(child: Text('No data for page ${widget.pageNo}'));
    }

    // When Tajweed is enabled, render the page's verses as colour-coded plain
    // Arabic (same verses/pages, reflowed) instead of the QCF page glyphs.
    final tajweedEnabled =
        context.watch<TajweedProvider>().enabled && _pageAyas.isNotEmpty;

    return _buildPage(context, lines, tajweedEnabled: tajweedEnabled);
  }

  Widget _buildPage(
    BuildContext context,
    List<MushafLine> lines, {
    bool tajweedEnabled = false,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isFirstTwoPages = widget.pageNo == 1 || widget.pageNo == 2;
    final lineCount = lines.length;
    final isSpecialPage = lineCount == 8;

    final textSizes = _computeTextSizes(screenSize, isSpecialPage);

    final startAyaId = _meta?.startAya ?? 0;
    var nextAyaId = startAyaId;

    int? sectionFirstLineId;
    int sectionStartAya = startAyaId;

    final List<Widget> lineWidgets = [];
    final List<Widget> topWidgets = [];
    var insertedBeforeFirstAya = false;
    bool tooltipPlaced = false;
    int? tajweedSectionSura;

    if (isSpecialPage) lineWidgets.add(const SizedBox(height: 8));

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.lineId == -1) {
        if (isFirstTwoPages) {
          topWidgets.add(_buildSuraHeading(line, textSizes));
        } else {
          lineWidgets.add(_buildSuraHeading(line, textSizes));
        }
        sectionFirstLineId = null;
        tajweedSectionSura = null;
      } else if (line.lineId == 0) {
        lineWidgets.add(_buildBismillahLine(line, textSizes));
      } else {
        if (!insertedBeforeFirstAya && widget.beforeFirstAya != null) {
          lineWidgets.add(widget.beforeFirstAya!);
          insertedBeforeFirstAya = true;
        }

        // Tajweed reading mode: emit each sura-section's verses once as a single
        // colour-coded paragraph, skipping the per-line QCF rendering.
        if (tajweedEnabled) {
          if (tajweedSectionSura != line.suraId) {
            tajweedSectionSura = line.suraId;
            final sectionAyas =
                _pageAyas.where((a) => a.suraNo == line.suraId).toList();
            if (sectionAyas.isNotEmpty) {
              lineWidgets.add(_buildTajweedSection(sectionAyas, textSizes));
            }
          }
          continue;
        }

        if (sectionFirstLineId == null) {
          sectionFirstLineId = line.lineId;
          sectionStartAya = nextAyaId;
        }
        final lineAyaId = sectionStartAya + (line.lineId - sectionFirstLineId);
        final previousAyaLine = _findAdjacentAyaLine(lines, index, searchBackwards: true);
        final nextAyaLine = _findAdjacentAyaLine(lines, index, searchBackwards: false);

        final result = _buildAyaLine(
          line,
          textSizes,
          lineAyaId: lineAyaId,
          previousAyaLine: previousAyaLine,
          nextAyaLine: nextAyaLine,
          tooltipLink: !tooltipPlaced ? _tooltipLink : null,
        );
        if (result.containsSelectedAya && !tooltipPlaced && widget.actionRow != null) {
          tooltipPlaced = true;
          lineWidgets.add(result.widget);
          _scheduleTooltipOverlay();
        } else {
          lineWidgets.add(result.widget);
        }
        nextAyaId = result.nextAyaId;
      }
    }

    if (isSpecialPage) lineWidgets.add(const SizedBox(height: 8));
    if (!tooltipPlaced) _removeTooltipOverlay();

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => widget.onAyaTap?.call(),
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            children: [
              if (!isSpecialPage) _buildPageHeader(textSizes),
              if (!isLandscape && isFirstTwoPages)
                const SizedBox(height: kToolbarHeight),
              if (!isLandscape && isFirstTwoPages) ...topWidgets,
              Expanded(
                child: PinchZoomView(
                  child: Center(
                    child: tajweedEnabled
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: LayoutBuilder(
                              builder: (context, constraints) => FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isLandscape && isFirstTwoPages)
                                        const SizedBox(height: kToolbarHeight),
                                      if (isLandscape && isFirstTwoPages)
                                        ...topWidgets,
                                      ...lineWidgets,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
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
                      fontSize: isLandscape ? textSizes.pageNoSize * 0.75 : textSizes.pageNoSize,
                      color: _textColor.withValues(alpha: 0.45),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  MushafLine? _findAdjacentAyaLine(List<MushafLine> lines, int index, {required bool searchBackwards}) {
    final step = searchBackwards ? -1 : 1;
    final current = lines[index];
    for (var cursor = index + step; cursor >= 0 && cursor < lines.length; cursor += step) {
      final candidate = lines[cursor];
      if (candidate.lineId == -1 || candidate.suraId != current.suraId) return null;
      if (candidate.lineId > 0) return candidate;
    }
    return null;
  }

  Widget _buildPageHeader(_TextSizes sizes) {
    final suraDisplay = _suraGlyph != null && _suraGlyph!.isNotEmpty
        ? MushafTextUtils.reverseText(_suraGlyph!)
        : '';
    final juzNo = _meta?.juzNo ?? 0;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final headerFontSize =
        isLandscape ? sizes.headTextSize * 0.5 : sizes.headTextSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          if (juzNo > 0)
            Text(
              'Juz $juzNo',
              style: TextStyle(fontSize: headerFontSize * 0.75, color: Colors.grey),
            ),
          const Spacer(),
          if (suraDisplay.isNotEmpty)
            Text(
              suraDisplay,
              style: TextStyle(
                fontFamily: _bsmlFontFamily,
                fontSize: headerFontSize,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuraHeading(MushafLine line, _TextSizes sizes) {
    final segments = MushafTextUtils.parseLine(line.data, isHeadingOrBismillah: true);
    final displayText = segments.isNotEmpty ? segments.first.text : '';
    final isPotrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: isPotrait ? 10 : 50),
      child: Center(
        child: GestureDetector(
          onTap: () => widget.onAyaTap?.call(),
          onLongPress: () => widget.onAyaLongPress?.call(0, line.suraId),
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
                  fontFamily: _bsmlFontFamily,
                  fontSize: sizes.headTextSize,
                  height: 1.0,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBismillahLine(MushafLine line, _TextSizes sizes) {
    final segments = MushafTextUtils.parseLine(line.data, isHeadingOrBismillah: true);
    final displayText = segments.isNotEmpty ? segments.first.text : '';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Center(
        child: GestureDetector(
          onTap: () => widget.onAyaTap?.call(),
          onLongPress: () => widget.onAyaLongPress?.call(1, line.suraId),
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: _bsmlFontFamily,
              fontSize: sizes.headTextSize,
              height: 1.4,
              color: _textColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds one colour-coded Tajweed paragraph for all of a sura's [ayas] on the
  /// current page. Used only when Tajweed is enabled (reflowed plain Arabic).
  Widget _buildTajweedSection(
    List<({int ayaId, int suraNo, int ayaNo})> ayas,
    _TextSizes sizes,
  ) {
    final baseStyle = AppTextTheme.tajweedArabiStyle(context).copyWith(
      fontSize: sizes.ayaTextSize,
      height: sizes.lineHeightFactor,
      color: _textColor,
    );
    // Ayah-end marker keeps the standard reading font; QuranTaha renders the
    // ﴾﴿ ornamental parentheses as oversized decorative glyphs.
    final markerStyle = AppTextTheme.surahArabiStyle(context).copyWith(
      fontSize: sizes.ayaTextSize,
      height: sizes.lineHeightFactor,
      color: _highlightColor,
    );

    final spans = <InlineSpan>[];
    for (final aya in ayas) {
      final html = TajweedHtmlService.displayHtmlFor(aya.suraNo, aya.ayaNo);
      if (html == null) continue;
      final isActive =
          widget.playingAyaId == aya.ayaId || widget.selectedAyaId == aya.ayaId;
      final ayaStyle = isActive
          ? baseStyle.copyWith(
              backgroundColor: _highlightColor.withValues(alpha: 0.15),
            )
          : baseStyle;
      spans.addAll(parseTajweedHtml(html, ayaStyle));
      spans.add(
        TextSpan(
          text: ' \uFD3E${_toArabicNumerals(aya.ayaNo)}\uFD3F ',
          style: markerStyle,
        ),
      );
    }

    if (spans.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text.rich(
        TextSpan(children: spans),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      ),
    );
  }

  String _toArabicNumerals(int number) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabic[int.parse(d)])
        .join();
  }

  _AyaLineResult _buildAyaLine(
    MushafLine line,
    _TextSizes sizes, {
    required int lineAyaId,
    required MushafLine? previousAyaLine,
    required MushafLine? nextAyaLine,
    LayerLink? tooltipLink,
  }) {
    final rawData = line.data;
    final parts = rawData.split('▌');
    final segmentData = <({String text, bool addSpace})>[];
    var firstVisibleSegment = true;
    for (final part in parts) {
      final reversed = MushafTextUtils.reverseText(part.replaceAll('▼', '')).replaceAll('▌', '').trim();
      if (reversed.isEmpty) continue;
      segmentData.add((text: reversed, addSpace: firstVisibleSegment));
      firstVisibleSegment = false;
    }

    final segmentCount = segmentData.length;
    final List<Widget> rowChildren = [];
    bool containsSelectedAya = false;
    bool selectedAyaContinues = false;

    for (var segmentIndex = 0; segmentIndex < segmentData.length; segmentIndex++) {
      var text = segmentData[segmentIndex].text;
      if (segmentData[segmentIndex].addSpace) text = '$text\u0020';

      final thisAyaId = lineAyaId + segmentIndex;
      final isHighlighted = thisAyaId == widget.selectedAyaId;
      final isPlayingAya = thisAyaId == widget.playingAyaId;
      final ayaNoForSegment = line.lineId + segmentIndex;
      final continuesOnNextLine = nextAyaLine != null && nextAyaLine.lineId == ayaNoForSegment;

      if (isHighlighted) {
        containsSelectedAya = true;
        if (continuesOnNextLine) selectedAyaContinues = true;
      }

      Widget segmentWidget = GestureDetector(
        onLongPress: () => widget.onAyaLongPress?.call(thisAyaId, line.suraId),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontFamily: _pageFontFamily,
            fontSize: sizes.ayaTextSize,
            height: sizes.lineHeightFactor,
            color: isHighlighted ? _highlightColor : (isPlayingAya ? _playingColor : _textColor),
          ),
        ),
      );

      if (isHighlighted && tooltipLink != null) {
        segmentWidget = CompositedTransformTarget(link: tooltipLink, child: segmentWidget);
      }

      rowChildren.add(segmentWidget);
    }

    final widget_ = LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: rowChildren,
          ),
        ),
      ),
    );

    return _AyaLineResult(
      widget: widget_,
      nextAyaId: lineAyaId + segmentCount,
      containsSelectedAya: containsSelectedAya,
      selectedAyaContinues: selectedAyaContinues,
    );
  }

  void _scheduleTooltipOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.actionRow == null) return;
      _removeTooltipOverlay();
      _tooltipOverlay = OverlayEntry(
        builder: (context) => _TooltipOverlayWidget(
          link: _tooltipLink,
          actionRow: widget.actionRow!,
          onDismiss: () => widget.onDismissSelection?.call(),
        ),
      );
      Overlay.of(context).insert(_tooltipOverlay!);
    });
  }

  void _removeTooltipOverlay() {
    _tooltipOverlay?.remove();
    _tooltipOverlay?.dispose();
    _tooltipOverlay = null;
  }

  _TextSizes _computeTextSizes(Size screenSize, bool isSpecialPage) {
    double baseFontSize = widget.quranFontSize;
    if (isSpecialPage) baseFontSize *= 1.15;
    return _TextSizes(
      ayaTextSize: baseFontSize,
      headTextSize: baseFontSize * 0.85,
      lineHeightFactor: 1.6,
      pageNoSize: baseFontSize * 0.55,
    );
  }
}

class _TextSizes {
  const _TextSizes({
    required this.ayaTextSize,
    required this.headTextSize,
    required this.lineHeightFactor,
    required this.pageNoSize,
  });

  final double ayaTextSize;
  final double headTextSize;
  final double lineHeightFactor;
  final double pageNoSize;
}

class _AyaLineResult {
  const _AyaLineResult({
    required this.widget,
    required this.nextAyaId,
    required this.containsSelectedAya,
    required this.selectedAyaContinues,
  });

  final Widget widget;
  final int nextAyaId;
  final bool containsSelectedAya;
  final bool selectedAyaContinues;
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => color != oldDelegate.color;
}

class _TooltipOverlayWidget extends StatelessWidget {
  const _TooltipOverlayWidget({
    required this.link,
    required this.actionRow,
    required this.onDismiss,
  });

  final LayerLink link;
  final Widget actionRow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.bottomCenter,
          showWhenUnlinked: false,
          child: FractionalTranslation(
            translation: const Offset(0, -0.1),
            child: _ClampedTooltip(actionRow: actionRow, surfaceColor: surfaceColor),
          ),
        ),
      ],
    );
  }
}

class _ClampedTooltip extends StatefulWidget {
  const _ClampedTooltip({required this.actionRow, required this.surfaceColor});
  final Widget actionRow;
  final Color surfaceColor;

  @override
  State<_ClampedTooltip> createState() => _ClampedTooltipState();
}

class _ClampedTooltipState extends State<_ClampedTooltip> {
  final GlobalKey _tooltipKey = GlobalKey();
  double _shiftX = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _clampPosition());
  }

  @override
  void didUpdateWidget(covariant _ClampedTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _clampPosition());
  }

  void _clampPosition() {
    if (!mounted) return;
    final box = _tooltipKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final globalPos = box.localToGlobal(Offset.zero);
    final tooltipWidth = box.size.width;

    double shift = 0;
    const padding = 8.0;

    if (globalPos.dx + tooltipWidth > screenWidth - padding) {
      shift = (screenWidth - padding) - (globalPos.dx + tooltipWidth);
    }
    if (globalPos.dx + shift < padding) {
      shift = padding - globalPos.dx;
    }

    if (shift != _shiftX) {
      setState(() => _shiftX = shift);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(_shiftX, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            key: _tooltipKey,
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: widget.surfaceColor,
            child: widget.actionRow,
          ),
          Transform.translate(
            offset: Offset(-_shiftX, 0),
            child: CustomPaint(
              size: const Size(14, 7),
              painter: _TrianglePainter(color: widget.surfaceColor),
            ),
          ),
        ],
      ),
    );
  }
}
