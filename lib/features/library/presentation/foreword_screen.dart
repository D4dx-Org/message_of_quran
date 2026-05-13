import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/foreword_model.dart';
import 'package:the_message_of_the_quran/core/services/database/foreword_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/foreword_parser.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/mushaf/data/mushaf_repository.dart';
import 'package:the_message_of_the_quran/features/mushaf/utils/mushaf_text_utils.dart';

class ForewordScreen extends StatelessWidget {
  const ForewordScreen({super.key});

  static Future<({ForewordModel? foreword, String bismillahGlyph})>
      _loadData() async {
    final results = await Future.wait([
      ForewordDbHelper.getForeword(),
      MushafRepository().getBismillahGlyph(2),
    ]);
    final foreword = results[0] as ForewordModel?;
    final rawGlyph = results[1] as String;
    final segments = rawGlyph.isNotEmpty
        ? MushafTextUtils.parseLine(rawGlyph, isHeadingOrBismillah: true)
        : <AyaSegment>[];
    final glyph = segments.isNotEmpty ? segments.first.text : '';
    return (foreword: foreword, bismillahGlyph: glyph);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          'Foreword',
          style: AppTextTheme.titleRegular,
        ),
      ),
      child: FutureBuilder<({ForewordModel? foreword, String bismillahGlyph})>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load foreword.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }
          final foreword = snapshot.data?.foreword;
          if (foreword == null) {
            return const Center(
              child: Text(
                'No foreword available.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }
          return _ForewordContent(
            body: foreword.body,
            bismillahGlyph: snapshot.data!.bismillahGlyph,
          );
        },
      ),
    );
  }
}

// ─── Content widget with scroll and footnote navigation ─────────────────────

class _ForewordContent extends StatefulWidget {
  const _ForewordContent({required this.body, required this.bismillahGlyph});
  final String body;
  final String bismillahGlyph;

  @override
  State<_ForewordContent> createState() => _ForewordContentState();
}

class _ForewordContentState extends State<_ForewordContent> {
  late final List<ForewordSegment> _segments;
  late final List<ForewordSegment> _footnotes;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _footnoteKeys = {};

  @override
  void initState() {
    super.initState();
    _segments = ForewordParser.parse(widget.body);
    _footnotes = _segments
        .where((s) => s.type == ForewordSegmentType.footnote)
        .toList();
    for (final fn in _footnotes) {
      final num = _extractFootnoteNumber(fn.text);
      if (num != null) {
        _footnoteKeys[num] = GlobalKey();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int? _extractFootnoteNumber(String text) {
    final match = RegExp(r'^(\d+)\.\s').firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  void _scrollToFootnote(int number) {
    final key = _footnoteKeys[number];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodySegments = _segments
        .where((s) => s.type != ForewordSegmentType.footnote)
        .toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Bismillah ───
          Center(
            child: widget.bismillahGlyph.isNotEmpty
                ? Text(
                    widget.bismillahGlyph,
                    textDirection: TextDirection.ltr,
                    style: AppTextTheme.forewordBismillah(context).copyWith(
                      fontFamily: 'QCF_BSML',
                      fontSize: 30,
                      height: 1.4,
                    ),
                  )
                : Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                    textDirection: TextDirection.rtl,
                    style: AppTextTheme.forewordBismillah(context),
                  ),
          ),
          const SizedBox(height: 20),
          // ─── Ornamental divider ───
          _OrnamentalDivider(isDark: isDark),
          const SizedBox(height: 20),
          // ─── Title ───
          Center(
            child: Text(
              'FOREWORD',
              style: AppTextTheme.forewordTitle(context),
            ),
          ),
          const SizedBox(height: 28),
          // ─── Body segments ───
          ..._buildBodySegments(bodySegments, context),
          // ─── Footnotes section ───
          if (_footnotes.isNotEmpty) ...[
            const SizedBox(height: 32),
            _OrnamentalDivider(isDark: isDark),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'NOTES',
                style: AppTextTheme.forewordTitle(context).copyWith(
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._buildFootnotes(context),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBodySegments(
    List<ForewordSegment> segments,
    BuildContext context,
  ) {
    final widgets = <Widget>[];
    bool isFirstBody = true;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];

      switch (segment.type) {
        case ForewordSegmentType.quranVerse:
          widgets.add(_buildQuranVerse(segment.text, context));
          break;
        case ForewordSegmentType.sectionStart:
          widgets.add(const SizedBox(height: 8));
          widgets.add(_buildSectionStart(segment.text, context));
          break;
        case ForewordSegmentType.body:
          if (isFirstBody) {
            isFirstBody = false;
            widgets.add(_buildDropCapParagraph(segment.text, context));
          } else {
            widgets.add(_buildBodyParagraph(segment.text, context));
          }
          break;
        case ForewordSegmentType.footnote:
          break;
      }
    }
    return widgets;
  }

  Widget _buildQuranVerse(String text, BuildContext context) {
    // Check if it ends with a Quranic reference like "(Qur'an 18:109)."
    final refPattern = RegExp(r"\(Qur.an[,\s]+\d+:\d+\)\.?$");
    final refMatch = refPattern.firstMatch(text);

    if (refMatch != null) {
      final verseText = text.substring(0, refMatch.start).trim();
      final ref = refMatch.group(0)!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            Text(
              verseText,
              textAlign: TextAlign.center,
              style: AppTextTheme.forewordQuote(context),
            ),
            const SizedBox(height: 10),
            Text(
              ref,
              textAlign: TextAlign.center,
              style: AppTextTheme.forewordVerseRef(context),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextTheme.forewordQuote(context),
      ),
    );
  }

  Widget _buildDropCapParagraph(String text, BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final firstChar = text[0];
    final restText = text.substring(1);
    final restParts = ForewordParser.splitBodyWithRefs(restText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drop cap letter
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 2),
            child: Text(
              firstChar,
              style: AppTextTheme.forewordDropCap(context),
            ),
          ),
          // Rest of the paragraph
          Expanded(
            child: Text.rich(
              TextSpan(children: _buildTextSpans(restParts, context)),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionStart(String text, BuildContext context) {
    // Find the first space-separated caps section (e.g., "THE WORK" or "AS REGARDS")
    final capsMatch = RegExp(r'^([A-Z\s]+?)(?=\s[a-z])').firstMatch(text);

    if (capsMatch != null) {
      final capsText = capsMatch.group(1)!;
      final remaining = text.substring(capsMatch.end);
      final remainingParts = ForewordParser.splitBodyWithRefs(remaining);

      return Padding(
        padding: const EdgeInsets.only(bottom: 14, top: 16),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: capsText,
                style: AppTextTheme.forewordBody(context).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              ..._buildTextSpans(remainingParts, context),
            ],
          ),
          textAlign: TextAlign.justify,
        ),
      );
    }

    final parts = ForewordParser.splitBodyWithRefs(text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 16),
      child: Text.rich(
        TextSpan(children: _buildTextSpans(parts, context)),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildBodyParagraph(String text, BuildContext context) {
    final parts = ForewordParser.splitBodyWithRefs(text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text.rich(
        TextSpan(children: _buildTextSpans(parts, context)),
        textAlign: TextAlign.justify,
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(
    List<ForewordTextPart> parts,
    BuildContext context,
  ) {
    final spans = <InlineSpan>[];
    for (final part in parts) {
      if (part.isFootnoteRef) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: GestureDetector(
              onTap: () => _scrollToFootnote(part.footnoteNumber!),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  part.text,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.appThemePrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: part.text,
            style: AppTextTheme.forewordBody(context),
          ),
        );
      }
    }
    return spans;
  }

  List<Widget> _buildFootnotes(BuildContext context) {
    return _footnotes.map((fn) {
      final num = _extractFootnoteNumber(fn.text);
      return Padding(
        key: num != null ? _footnoteKeys[num] : null,
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${num ?? ""}.',
                style: AppTextTheme.forewordFootnote(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                fn.text.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                style: AppTextTheme.forewordFootnote(context),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ─── Decorative divider with center diamond ─────────────────────────────────

class _OrnamentalDivider extends StatelessWidget {
  const _OrnamentalDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark
        ? Colors.white38
        : AppTheme.appThemePrimary.withValues(alpha: 0.4);

    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.0),
                    color,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 6,
                height: 6,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
