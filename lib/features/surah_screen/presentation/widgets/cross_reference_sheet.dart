import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_model.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/core/services/database/arabic_block_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/interpretations_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/translation_block_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/cross_reference_parser.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

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
      constraints:
          bsMaxWidth != null ? BoxConstraints(maxWidth: bsMaxWidth) : null,
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

  @override
  State<CrossReferenceSheet> createState() => _CrossReferenceSheetState();
}

class _CrossReferenceSheetState extends State<CrossReferenceSheet> {
  bool _loading = true;
  ArabicBlockModel? _arabic;
  TranslationBlockModel? _translation;
  List<InterpretationModel> _interpretation = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final isMl = context.read<LanguageProvider>().isMalayalam;

    final results = await Future.wait([
      ArabicBlockDbHelper.getArabicBlockByVerse(
          widget.surahNumber, widget.ayahNumber),
      TranslationBlockDbHelper.getTranslationBlockByVerse(
          widget.surahNumber, widget.ayahNumber,
          malayalam: isMl),
    ]);

    final arabic = results[0] as ArabicBlockModel?;
    final translation = results[1] as TranslationBlockModel?;

    // If a note number was provided, also fetch interpretation
    List<InterpretationModel> interp = [];
    if (widget.noteNumber != null) {
      interp = await InterpretationsDbHelper.getinterpretations(
        surahNumber: widget.surahNumber,
        interpretationNumber: widget.noteNumber!,
        malayalam: isMl,
      );
    }

    if (!mounted) return;
    setState(() {
      _arabic = arabic;
      _translation = translation;
      _interpretation = interp;
      _loading = false;
    });
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

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
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
          // Header: close + title + copy/share
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Copy
                IconButton(
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
                  icon: Icon(
                    Icons.copy_outlined,
                    size: 20,
                    color:
                        _loading ? Colors.grey[400] : AppTheme.appIconTheme,
                  ),
                ),
                // Share
                IconButton(
                  tooltip: 'Share',
                  onPressed: _loading
                      ? null
                      : () async {
                          final text = _combinedText();
                          if (text.trim().isNotEmpty) {
                            await Share.share(text);
                          }
                        },
                  icon: Icon(
                    Icons.share_outlined,
                    size: 20,
                    color:
                        _loading ? Colors.grey[400] : AppTheme.appIconTheme,
                  ),
                ),
                const Spacer(),
                // Close
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22),
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
                        child: Center(
                          child: Text('Verse not found'),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Verse range label
                            Center(
                              child: Text(
                                'Verse Range ${widget.ayahNumber}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.grey[600],
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

  /// Builds translation text with tappable `(N)` footnote markers.
  Widget _buildTranslationRichText(
    BuildContext context,
    String text,
    FontSizeChangerProvider fontSettings,
    bool isMl,
  ) {
    // Strip HTML <br> tags
    final cleaned =
        text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n').trim();
    // Strip verse-number prefix (e.g. "51 ")
    final displayText = cleaned.replaceFirst(RegExp(r'^\d+[\s.]*'), '');

    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\((\d+)\)');
    int lastEnd = 0;
    bool found = false;

    for (final match in pattern.allMatches(displayText)) {
      found = true;
      // Plain text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: displayText.substring(lastEnd, match.start),
          style: AppTextTheme.surahMalayalamStyle(context),
        ));
      }
      // Tappable (N)
      final num = int.tryParse(match.group(1)!);
      spans.add(TextSpan(
        text: '(${match.group(1)})',
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (num != null) {
              _showNestedInterpretation(context, num);
            }
          },
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppTheme.appIconTheme,
        ),
      ));
      lastEnd = match.end;
    }

    if (!found) {
      // No footnotes found, just display as-is
      spans.add(TextSpan(
        text: displayText,
        style: AppTextTheme.surahMalayalamStyle(context),
      ));
    } else if (lastEnd < displayText.length) {
      spans.add(TextSpan(
        text: displayText.substring(lastEnd),
        style: AppTextTheme.surahMalayalamStyle(context),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign:
          fontSettings.translationJustify ? TextAlign.justify : TextAlign.start,
    );
  }

  /// Shows a nested interpretation bottom sheet for a footnote in the
  /// referenced surah.
  void _showNestedInterpretation(BuildContext context, int footnoteNumber) {
    final isMl = context.read<LanguageProvider>().isMalayalam;
    final bsMaxWidth = ResponsiveHelper.bottomSheetMaxWidth(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      constraints:
          bsMaxWidth != null ? BoxConstraints(maxWidth: bsMaxWidth) : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NestedInterpretationSheet(
        surahNumber: widget.surahNumber,
        footnoteNumber: footnoteNumber,
        isMalayalam: isMl,
      ),
    );
  }

  /// Builds interpretation text with tappable cross-references.
  Widget _buildInterpretationWithCrossRefs(
    BuildContext context,
    String text,
    int currentSurahNumber,
  ) {
    final segments = parseForCrossReferences(text, currentSurahNumber);
    if (segments.length == 1 && !segments.first.isCrossReference) {
      return Text(
        text,
        style: AppTextTheme.surahInterpretationStyle(context),
      );
    }

    final spans = <InlineSpan>[];
    for (final seg in segments) {
      if (seg.isCrossReference) {
        final ref = seg.crossReference!;
        spans.add(TextSpan(
          text: seg.text,
          style: AppTextTheme.surahInterpretationStyle(context).copyWith(
            color: AppTheme.appIconTheme,
            decoration: TextDecoration.underline,
            decorationColor: AppTheme.appIconTheme,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (ref.ayahNumber != null) {
                CrossReferenceSheet.show(
                  context,
                  surahNumber: ref.surahNumber,
                  ayahNumber: ref.ayahNumber!,
                  noteNumber: ref.noteNumber,
                );
              } else if (ref.noteNumber != null) {
                _showNestedInterpretation(context, ref.noteNumber!);
              }
            },
        ));
      } else {
        spans.add(TextSpan(
          text: seg.text,
          style: AppTextTheme.surahInterpretationStyle(context),
        ));
      }
    }

    return Text.rich(TextSpan(children: spans));
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

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final items = await InterpretationsDbHelper.getinterpretations(
      surahNumber: widget.surahNumber,
      interpretationNumber: widget.footnoteNumber,
      malayalam: widget.isMalayalam,
    );
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMl = context.read<LanguageProvider>().isMalayalam;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  isMl ? 'വിശദീകരണം' : 'Explanation',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22),
                ),
              ],
            ),
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
    final segments = parseForCrossReferences(text, currentSurahNumber);
    if (segments.length == 1 && !segments.first.isCrossReference) {
      return Text(
        text,
        style: AppTextTheme.surahInterpretationStyle(context),
      );
    }

    final spans = <InlineSpan>[];
    for (final seg in segments) {
      if (seg.isCrossReference) {
        final ref = seg.crossReference!;
        spans.add(TextSpan(
          text: seg.text,
          style: AppTextTheme.surahInterpretationStyle(context).copyWith(
            color: AppTheme.appIconTheme,
            decoration: TextDecoration.underline,
            decorationColor: AppTheme.appIconTheme,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (ref.ayahNumber != null) {
                CrossReferenceSheet.show(
                  context,
                  surahNumber: ref.surahNumber,
                  ayahNumber: ref.ayahNumber!,
                  noteNumber: ref.noteNumber,
                );
              }
            },
        ));
      } else {
        spans.add(TextSpan(
          text: seg.text,
          style: AppTextTheme.surahInterpretationStyle(context),
        ));
      }
    }

    return Text.rich(TextSpan(children: spans));
  }
}
