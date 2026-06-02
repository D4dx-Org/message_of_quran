import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_model.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/core/services/database/arabic_block_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/interpretations_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/surah_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/translation_block_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/cross_reference_parser.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/utils/translation_alignment.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/interpretation_note_marker.dart';

class InterpretationSheetSurahHeaderText {
  const InterpretationSheetSurahHeaderText({this.title, this.subtitle});

  final String? title;
  final String? subtitle;

  bool get hasTitle => title != null && title!.trim().isNotEmpty;
  bool get hasSubtitle => subtitle != null && subtitle!.trim().isNotEmpty;

  List<String> toLines() {
    return [
      if (hasTitle) title!.trim(),
      if (hasSubtitle) subtitle!.trim(),
    ];
  }
}

InterpretationSheetSurahHeaderText formatInterpretationSheetSurahHeader({
  required bool isMalayalam,
  required SurahModel? surah,
}) {
  if (surah == null) {
    return const InterpretationSheetSurahHeaderText();
  }

  final displayText = formatSurahListDisplayText(
    isMalayalam: isMalayalam,
    surahName: surah.name,
    surahTranslation: surah.description,
    malayalamName: surah.malayalamName,
    surahNumber: surah.surahNumber,
  );
  final title = displayText.title.trim();
  final subtitle = displayText.subtitle.trim();

  return InterpretationSheetSurahHeaderText(
    title: title.isEmpty ? null : title,
    subtitle: subtitle.isEmpty ? null : subtitle,
  );
}

String formatInterpretationMetadataLabel({
  required bool isMalayalam,
  required int surahNumber,
  required int interpretationNumber,
  List<int> ayahNumbers = const [],
}) {
  final parts = <String>[
    isMalayalam ? 'സൂറത്ത് $surahNumber' : 'Surah $surahNumber',
    isMalayalam
        ? 'ഇന്റർപ്രെറ്റേഷൻ $interpretationNumber'
        : 'Interpretation $interpretationNumber',
  ];

  final verseLabel = _formatInterpretationVerseLabel(
    isMalayalam: isMalayalam,
    ayahNumbers: ayahNumbers,
  );
  if (verseLabel.isNotEmpty) {
    parts.add(verseLabel);
  }

  return parts.join(' • ');
}

String _formatInterpretationVerseLabel({
  required bool isMalayalam,
  required List<int> ayahNumbers,
}) {
  final formatted = _formatInterpretationAyahNumbers(ayahNumbers);
  if (formatted.isEmpty) return '';

  final prefix = ayahNumbers.toSet().where((n) => n > 0).length == 1
      ? (isMalayalam ? 'ആയത്ത്' : 'Verse')
      : (isMalayalam ? 'ആയത്തുകൾ' : 'Verses');
  return '$prefix $formatted';
}

String _formatInterpretationAyahNumbers(List<int> ayahNumbers) {
  final normalized = ayahNumbers.toSet().where((n) => n > 0).toList()..sort();
  if (normalized.isEmpty) return '';
  if (normalized.length == 1) return '${normalized.first}';

  bool contiguous = true;
  for (int i = 1; i < normalized.length; i++) {
    if (normalized[i] != normalized[i - 1] + 1) {
      contiguous = false;
      break;
    }
  }

  if (contiguous) {
    return '${normalized.first}-${normalized.last}';
  }
  return normalized.join(', ');
}

const _kInterpretationSheetDragHandlePadding = EdgeInsets.only(
  top: 8,
  bottom: 2,
);
const _kInterpretationSheetHeaderPadding = EdgeInsets.fromLTRB(20, 0, 12, 8);
const _kInterpretationSheetActionOffset = Offset(0, -10);
const _kInterpretationSheetActionConstraints = BoxConstraints.tightFor(
  width: 24,
  height: 24,
);
const _kInterpretationSheetActionIconSize = 24.0;
const _kInterpretationSheetActionSplashRadius = 18.0;

Widget _buildCompactSheetActionButton({
  required String tooltip,
  required VoidCallback? onPressed,
  required IconData icon,
  Color? color,
}) {
  return Transform.translate(
    offset: _kInterpretationSheetActionOffset,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: _kInterpretationSheetActionConstraints,
      visualDensity: VisualDensity.compact,
      splashRadius: _kInterpretationSheetActionSplashRadius,
      icon: Icon(
        icon,
        size: _kInterpretationSheetActionIconSize,
        color: color,
      ),
    ),
  );
}

class InterpretationSheetHeader extends StatelessWidget {
  final InterpretationSheetSurahHeaderText surahHeader;
  final String metadataLabel;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry closeButtonPadding;
  final Offset closeButtonOffset;
  final double titleSpacing;
  final double metadataSpacing;
  final bool compactCloseButton;
  final Color? subtitleColor;
  final Color? metadataColor;

  const InterpretationSheetHeader({
    super.key,
    required this.surahHeader,
    required this.metadataLabel,
    this.onClose,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.closeButtonPadding = EdgeInsets.zero,
    this.closeButtonOffset = Offset.zero,
    this.titleSpacing = 2,
    this.metadataSpacing = 2,
    this.compactCloseButton = false,
    this.subtitleColor,
    this.metadataColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasSurahTitle = surahHeader.hasTitle;
    final hasSurahSubtitle = surahHeader.hasSubtitle;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final malayalamRegExp = RegExp(r'[\u0D00-\u0D7F]');
    final titleIsMalayalam =
      surahHeader.title != null && malayalamRegExp.hasMatch(surahHeader.title!);
    final subtitleIsMalayalam = surahHeader.subtitle != null &&
      malayalamRegExp.hasMatch(surahHeader.subtitle!);
    final metadataIsMalayalam = malayalamRegExp.hasMatch(metadataLabel);
    final resolvedSubtitleColor =
        subtitleColor ?? (isDark ? Colors.white70 : Colors.grey[700]);
    final resolvedMetadataColor =
        metadataColor ?? (isDark ? Colors.white60 : Colors.grey[600]);

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasSurahTitle)
                  Text(
                    surahHeader.title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextTheme.localizedLabel(
                      isMalayalam: titleIsMalayalam,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.0,
                    ),
                  ),
                if (hasSurahSubtitle) ...[
                  if (hasSurahTitle) SizedBox(height: titleSpacing),
                  Text(
                    surahHeader.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextTheme.localizedLabel(
                      isMalayalam: subtitleIsMalayalam,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: resolvedSubtitleColor,
                    ),
                  ),
                ],
                if (hasSurahTitle || hasSurahSubtitle)
                  SizedBox(height: metadataSpacing),
                Text(
                  metadataLabel,
                  style: AppTextTheme.localizedBody(
                    isMalayalam: metadataIsMalayalam,
                    fontSize: 12,
                    color: resolvedMetadataColor,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            Padding(
              padding: closeButtonPadding,
              child: Transform.translate(
                offset: closeButtonOffset,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  padding: compactCloseButton ? EdgeInsets.zero : null,
                  constraints: compactCloseButton
                      ? _kInterpretationSheetActionConstraints
                      : null,
                  visualDensity: compactCloseButton ? VisualDensity.compact : null,
                  splashRadius: compactCloseButton
                      ? _kInterpretationSheetActionSplashRadius
                      : null,
                  icon: const Icon(
                    Icons.close,
                    size: _kInterpretationSheetActionIconSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A self-contained bottom sheet that displays the Arabic text and translation
/// of a referenced Quranic verse (surah:ayah).
///
/// Fetches its own data from the database — independent of [SurahProvider].
/// Supports nested footnote tapping: if the translation contains `(N)` markers,
/// they open another bottom sheet with the interpretation for the referenced
/// surah's footnote.
class CrossReferenceSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;

  /// If non-null, also show the interpretation for this footnote/note number.
  final int? noteNumber;

  const CrossReferenceSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.noteNumber,
  });

  /// Convenience method to show the sheet as a modal bottom sheet.
  static void show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    int? noteNumber,
  }) {
    final bsMaxWidth = ResponsiveHelper.bottomSheetMaxWidth(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      constraints: bsMaxWidth != null
          ? BoxConstraints(maxWidth: bsMaxWidth)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CrossReferenceSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        noteNumber: noteNumber,
      ),
    );
  }

  /// Shows a note-only interpretation sheet for the referenced surah.
  static void showInterpretationNote(
    BuildContext context, {
    required int surahNumber,
    required int noteNumber,
  }) {
    final isMl = context.read<LanguageProvider>().isMalayalam;
    final bsMaxWidth = ResponsiveHelper.bottomSheetMaxWidth(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      constraints: bsMaxWidth != null
          ? BoxConstraints(maxWidth: bsMaxWidth)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NestedInterpretationSheet(
        surahNumber: surahNumber,
        footnoteNumber: noteNumber,
        isMalayalam: isMl,
      ),
    );
  }

  /// Routes a parsed cross-reference to the matching sheet.
  static void showParsedReference(BuildContext context, CrossReference ref) {
    if (ref.ayahNumber != null) {
      show(
        context,
        surahNumber: ref.surahNumber,
        ayahNumber: ref.ayahNumber!,
        noteNumber: ref.noteNumber,
      );
      return;
    }

    if (ref.noteNumber != null) {
      showInterpretationNote(
        context,
        surahNumber: ref.surahNumber,
        noteNumber: ref.noteNumber!,
      );
    }
  }

  @override
  State<CrossReferenceSheet> createState() => _CrossReferenceSheetState();
}

class _CrossReferenceSheetState extends State<CrossReferenceSheet> {
  bool _loading = true;
  ArabicBlockModel? _arabic;
  TranslationBlockModel? _translation;
  List<InterpretationModel> _interpretation = [];
  SurahModel? _surah;
  int _mlFootnoteMinNumber = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final isMl = context.read<LanguageProvider>().isMalayalam;

    final results = await Future.wait([
      ArabicBlockDbHelper.getArabicBlockByVerse(
        widget.surahNumber,
        widget.ayahNumber,
      ),
      TranslationBlockDbHelper.getTranslationBlockByVerse(
        widget.surahNumber,
        widget.ayahNumber,
        malayalam: isMl,
      ),
      SurahDbHelper.getSurahByNumber(widget.surahNumber),
    ]);

    final arabic = results[0] as ArabicBlockModel?;
    final translation = results[1] as TranslationBlockModel?;
    final surah = results[2] as SurahModel?;

    // If a note number was provided, also fetch interpretation
    List<InterpretationModel> interp = [];
    if (widget.noteNumber != null) {
      interp = await InterpretationsDbHelper.getinterpretations(
        surahNumber: widget.surahNumber,
        interpretationNumber: widget.noteNumber!,
        malayalam: isMl,
      );
    }

    int mlMin = 0;
    if (isMl) {
      final range = await InterpretationsDbHelper.getInterpretationRange(
        surahNumber: widget.surahNumber,
        malayalam: true,
      );
      mlMin = range['min'] ?? 0;
      if (mlMin < 0) mlMin = 0;
    }

    if (!mounted) return;
    setState(() {
      _arabic = arabic;
      _translation = translation;
      _interpretation = interp;
      _surah = surah;
      _mlFootnoteMinNumber = mlMin;
      _loading = false;
    });
  }

  String? _surahTitle(bool isMalayalam) {
    final surah = _surah;
    if (surah == null) return null;

    final title = formatSurahDisplayNameLine(
      isMalayalam: isMalayalam,
      surahName: surah.name,
      surahTranslation: surah.description,
      malayalamName: surah.malayalamName,
      surahNumber: surah.surahNumber,
    ).trim();
    return title.isEmpty ? null : title;
  }

  String _combinedText() {
    final buf = StringBuffer();
    buf.writeln('${widget.surahNumber}:${widget.ayahNumber}');
    if (_arabic?.arabicText != null) {
      buf.writeln();
      buf.writeln(_arabic!.arabicText);
    }
    if (_translation?.translationText != null) {
      buf.writeln();
      buf.writeln(_translation!.translationText);
    }
    for (final item in _interpretation) {
      buf.writeln();
      buf.writeln(item.interpretationText);
    }
    return buf.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final fontSettings = Provider.of<FontSizeChangerProvider>(context);
    final isMl = context.read<LanguageProvider>().isMalayalam;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetForegroundColor = isDark ? Colors.white : Colors.black;
    final surahTitle = _surahTitle(isMl);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: _kInterpretationSheetDragHandlePadding,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header actions
          Padding(
            padding: _kInterpretationSheetHeaderPadding,
            child: Row(
              children: [
                // Copy
                _buildCompactSheetActionButton(
                  tooltip: 'Copy',
                  onPressed: _loading
                      ? null
                      : () async {
                          final text = _combinedText();
                          if (text.trim().isNotEmpty) {
                            await Clipboard.setData(ClipboardData(text: text));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                  icon: Icons.copy_outlined,
                  color: _loading ? Colors.grey[400] : sheetForegroundColor,
                ),
                const SizedBox(width: 8),
                // Share
                _buildCompactSheetActionButton(
                  tooltip: 'Share',
                  onPressed: _loading
                      ? null
                      : () async {
                          final text = _combinedText();
                          if (text.trim().isNotEmpty) {
                            await Share.share(text);
                          }
                        },
                  icon: Icons.share_outlined,
                  color: _loading ? Colors.grey[400] : sheetForegroundColor,
                ),
                const Spacer(),
                // Close
                _buildCompactSheetActionButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icons.close,
                  color: sheetForegroundColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _arabic == null && _translation == null
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Verse not found')),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (surahTitle != null) ...[
                          Center(
                            child: Text(
                              surahTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextTheme.localizedLabel(
                                isMalayalam: isMl,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        // Verse range label
                        Center(
                          child: Text(
                            'Verse Range ${widget.ayahNumber}',
                            style: AppTextTheme.popinsDefault(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: sheetForegroundColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Arabic text
                        if (_arabic?.arabicText != null)
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              _arabic!.arabicText!,
                              style: AppTextTheme.surahArabiStyle(context),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (_arabic?.arabicText != null)
                          const SizedBox(height: 16),
                        // Translation text with tappable footnotes
                        if (_translation?.translationText != null)
                          _buildTranslationRichText(
                            context,
                            _translation!.translationText!,
                            fontSettings,
                            isMl,
                          ),
                        // Interpretation (if noteNumber was provided)
                        if (_interpretation.isNotEmpty) ...[
                          const Divider(height: 24),
                          for (final item in _interpretation)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildInterpretationWithCrossRefs(
                                context,
                                item.interpretationText,
                                widget.surahNumber,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Builds translation text with tappable footnote markers.
  /// Malayalam uses `[^N]` pattern; English uses `(N)` pattern.
  Widget _buildTranslationRichText(
    BuildContext context,
    String text,
    FontSizeChangerProvider fontSettings,
    bool isMl,
  ) {
    // Strip HTML <br> tags
    final cleaned = text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .trim();
    // Strip verse-number prefix (e.g. "51 ")
    final displayText = cleaned.replaceFirst(RegExp(r'^\d+[\s.]*'), '');

    final spans = <InlineSpan>[];
    final pattern = isMl ? RegExp(r'\[\^?(\d+)\]') : RegExp(r'\((\d+)\)');
    int lastEnd = 0;
    bool found = false;

    for (final match in pattern.allMatches(displayText)) {
      found = true;
      // Plain text before match
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: displayText.substring(lastEnd, match.start),
            style: AppTextTheme.surahTranslationStyle(
              context,
              isMalayalam: isMl,
            ),
          ),
        );
      }
      // Tappable footnote marker
      final num = int.tryParse(match.group(1)!);
      if (num == null) {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: AppTextTheme.surahTranslationStyle(
              context,
              isMalayalam: isMl,
            ),
          ),
        );
      } else {
        final displayNum = isMl ? num - _mlFootnoteMinNumber + 1 : num;
        spans.add(
          buildInterpretationNoteMarkerSpan(
            number: displayNum,
            onTap: () => _showNestedInterpretation(context, num),
          ),
        );
      }
      lastEnd = match.end;
    }

    if (!found) {
      // No footnotes found, just display as-is
      spans.add(
        TextSpan(
          text: displayText,
          style: AppTextTheme.surahTranslationStyle(
            context,
            isMalayalam: isMl,
          ),
        ),
      );
    } else if (lastEnd < displayText.length) {
      spans.add(
        TextSpan(
          text: displayText.substring(lastEnd),
          style: AppTextTheme.surahTranslationStyle(
            context,
            isMalayalam: isMl,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: resolveTranslationTextAlign(
        isMalayalam: isMl,
        justifyTranslation: fontSettings.translationJustify,
      ),
    );
  }

  /// Shows a nested interpretation bottom sheet for a footnote in the
  /// referenced surah.
  void _showNestedInterpretation(BuildContext context, int footnoteNumber) {
    CrossReferenceSheet.showInterpretationNote(
      context,
      surahNumber: widget.surahNumber,
      noteNumber: footnoteNumber,
    );
  }

  /// Builds interpretation text with tappable cross-references.
  Widget _buildInterpretationWithCrossRefs(
    BuildContext context,
    String text,
    int currentSurahNumber,
  ) {
    final isMl = context.read<LanguageProvider>().isMalayalam;
    final justifyInterpretation =
        context.watch<FontSizeChangerProvider>().interpretationJustify;
    final segments = parseForCrossReferences(text, currentSurahNumber);
    if (segments.length == 1 && !segments.first.isCrossReference) {
      return Text(
        text,
        style: AppTextTheme.surahInterpretationStyle(
          context,
          isMalayalam: isMl,
        ),
        textAlign: resolveInterpretationTextAlign(
          isMalayalam: isMl,
          justifyInterpretation: justifyInterpretation,
        ),
      );
    }

    final baseStyle = AppTextTheme.surahInterpretationStyle(
      context,
      isMalayalam: isMl,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDark ? const Color(0xff5B9BD5) : AppTheme.appIconTheme;
    final spans = <InlineSpan>[];
    for (final seg in segments) {
      if (seg.isCrossReference) {
        final ref = seg.crossReference!;
        spans.add(
          TextSpan(
            text: seg.text,
            style: baseStyle.copyWith(
              color: linkColor,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  CrossReferenceSheet.showParsedReference(context, ref),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: seg.text,
            style: baseStyle,
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: resolveInterpretationTextAlign(
        isMalayalam: isMl,
        justifyInterpretation: justifyInterpretation,
      ),
    );
  }
}

/// A simple nested bottom sheet that shows interpretation text for a given
/// surah + footnote number.
class _NestedInterpretationSheet extends StatefulWidget {
  final int surahNumber;
  final int footnoteNumber;
  final bool isMalayalam;

  const _NestedInterpretationSheet({
    required this.surahNumber,
    required this.footnoteNumber,
    required this.isMalayalam,
  });

  @override
  State<_NestedInterpretationSheet> createState() =>
      _NestedInterpretationSheetState();
}

class _NestedInterpretationSheetState
    extends State<_NestedInterpretationSheet> {
  bool _loading = true;
  List<InterpretationModel> _items = [];
  SurahModel? _surah;
  List<int> _referencedAyahNumbers = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final results = await Future.wait<dynamic>([
      InterpretationsDbHelper.getinterpretations(
        surahNumber: widget.surahNumber,
        interpretationNumber: widget.footnoteNumber,
        malayalam: widget.isMalayalam,
      ),
      SurahDbHelper.getSurahByNumber(widget.surahNumber),
      TranslationBlockDbHelper.getVerseNumbersForFootnote(
        widget.surahNumber,
        widget.footnoteNumber,
        malayalam: widget.isMalayalam,
      ),
    ]);

    final items = results[0] as List<InterpretationModel>;
    final surah = results[1] as SurahModel?;
    final referencedAyahs = results[2] as List<int>;
    if (!mounted) return;
    setState(() {
      _items = items;
      _surah = surah;
      _referencedAyahNumbers = referencedAyahs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMl = widget.isMalayalam;
    final surahHeader = formatInterpretationSheetSurahHeader(
      isMalayalam: isMl,
      surah: _surah,
    );
    final metadataLabel = formatInterpretationMetadataLabel(
      isMalayalam: isMl,
      surahNumber: widget.surahNumber,
      interpretationNumber: widget.footnoteNumber,
      ayahNumbers: _referencedAyahNumbers,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: _kInterpretationSheetDragHandlePadding,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          InterpretationSheetHeader(
            surahHeader: surahHeader,
            metadataLabel: metadataLabel,
            onClose: () => Navigator.of(context).pop(),
            padding: _kInterpretationSheetHeaderPadding,
            closeButtonOffset: _kInterpretationSheetActionOffset,
            titleSpacing: 0,
            compactCloseButton: true,
          ),
          const Divider(height: 1),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No explanation found')),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildInterpretationWithCrossRefs(
                            context,
                            item.interpretationText,
                            widget.surahNumber,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Builds interpretation text with tappable cross-references (nested).
  Widget _buildInterpretationWithCrossRefs(
    BuildContext context,
    String text,
    int currentSurahNumber,
  ) {
    final justifyInterpretation =
        context.watch<FontSizeChangerProvider>().interpretationJustify;
    final segments = parseForCrossReferences(text, currentSurahNumber);
    if (segments.length == 1 && !segments.first.isCrossReference) {
      return Text(
        text,
        style: AppTextTheme.surahInterpretationStyle(
          context,
          isMalayalam: widget.isMalayalam,
        ),
        textAlign: resolveInterpretationTextAlign(
          isMalayalam: widget.isMalayalam,
          justifyInterpretation: justifyInterpretation,
        ),
      );
    }

    final baseStyle = AppTextTheme.surahInterpretationStyle(
      context,
      isMalayalam: widget.isMalayalam,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDark ? const Color(0xff5B9BD5) : AppTheme.appIconTheme;
    final spans = <InlineSpan>[];
    for (final seg in segments) {
      if (seg.isCrossReference) {
        final ref = seg.crossReference!;
        spans.add(
          TextSpan(
            text: seg.text,
            style: baseStyle.copyWith(
              color: linkColor,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  CrossReferenceSheet.showParsedReference(context, ref),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: seg.text,
            style: baseStyle,
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: resolveInterpretationTextAlign(
        isMalayalam: widget.isMalayalam,
        justifyInterpretation: justifyInterpretation,
      ),
    );
  }
}
