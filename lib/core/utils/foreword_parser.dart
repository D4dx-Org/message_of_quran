// Parses the raw foreword body text into structured segments for rich display.
//
// The foreword text from the database has:
// - Body paragraphs separated by double newlines
// - Footnote paragraphs that start with "N. " (e.g., "1. It is to be...")
// - Footnote markers in body text as digits attached to preceding word (e.g., "revelation)1")
// - Opening Quranic verse (first paragraph, all-caps start "READ in the name...")
// - Inline Quranic quotes (italicized in the book)
// - Closing Quranic verse (last 2 paragraphs)

class ForewordParser {
  ForewordParser._();

  /// Parses raw foreword body text into a list of [ForewordSegment]s.
  static List<ForewordSegment> parse(String rawBody) {
    final paragraphs = rawBody.split(RegExp(r'\r?\n\r?\n'));
    final segments = <ForewordSegment>[];

    for (int i = 0; i < paragraphs.length; i++) {
      final text = paragraphs[i].trim();
      if (text.isEmpty) continue;

      final type = _classifyParagraph(text, i, paragraphs.length);
      segments.add(ForewordSegment(text: text, type: type));
    }

    return segments;
  }

  static ForewordSegmentType _classifyParagraph(
    String text,
    int index,
    int total,
  ) {
    // Footnote: starts with "N. " where N is 1-9 digits
    if (RegExp(r'^\d+\.\s').hasMatch(text)) {
      return ForewordSegmentType.footnote;
    }

    // First paragraph is always the opening Quranic verse
    if (index == 0) {
      return ForewordSegmentType.quranVerse;
    }

    // Last paragraph is the closing Quranic verse (starts with lowercase "if all the sea")
    if (index == total - 1) {
      return ForewordSegmentType.quranVerse;
    }

    // Paragraph 2 (index 2) is also a Quranic verse ("And be conscious of the Day...")
    if (text.startsWith('And be conscious of the Day on which you shall be brought back')) {
      return ForewordSegmentType.quranVerse;
    }

    // Section opener paragraphs (ALL CAPS start like "THE WORK", "AS REGARDS")
    if (RegExp(r'^[A-Z]{2,}\s').hasMatch(text) && index > 3) {
      return ForewordSegmentType.sectionStart;
    }

    return ForewordSegmentType.body;
  }

  /// Extracts footnote reference numbers from a body paragraph text.
  /// Returns a list of (position, footnoteNumber) pairs.
  static List<FootnoteRef> extractFootnoteRefs(String text) {
    final refs = <FootnoteRef>[];
    // Pattern: letter/punctuation immediately followed by digit(s) then space or end
    final pattern = RegExp(r'(?<=[a-zA-Z.,;:\)\]\!"])\d+(?=\s|$)');
    for (final match in pattern.allMatches(text)) {
      final num = int.tryParse(match.group(0)!);
      if (num != null && num >= 1 && num <= 20) {
        refs.add(FootnoteRef(
          position: match.start,
          endPosition: match.end,
          number: num,
        ));
      }
    }
    return refs;
  }

  /// Splits body text into parts: regular text segments and footnote markers.
  static List<ForewordTextPart> splitBodyWithRefs(String text) {
    final refs = extractFootnoteRefs(text);
    if (refs.isEmpty) {
      return [ForewordTextPart(text: text, isFootnoteRef: false)];
    }

    final parts = <ForewordTextPart>[];
    int lastEnd = 0;

    for (final ref in refs) {
      if (ref.position > lastEnd) {
        parts.add(ForewordTextPart(
          text: text.substring(lastEnd, ref.position),
          isFootnoteRef: false,
        ));
      }
      parts.add(ForewordTextPart(
        text: ref.number.toString(),
        isFootnoteRef: true,
        footnoteNumber: ref.number,
      ));
      lastEnd = ref.endPosition;
    }

    if (lastEnd < text.length) {
      parts.add(ForewordTextPart(
        text: text.substring(lastEnd),
        isFootnoteRef: false,
      ));
    }

    return parts;
  }
}

/// Represents a parsed segment of the foreword.
class ForewordSegment {
  final String text;
  final ForewordSegmentType type;

  const ForewordSegment({required this.text, required this.type});
}

enum ForewordSegmentType {
  /// Opening or closing Quranic verse (displayed in italic, indented)
  quranVerse,

  /// Regular body paragraph
  body,

  /// A paragraph that starts a new section (first word(s) in caps)
  sectionStart,

  /// A footnote paragraph (starts with "N. ")
  footnote,
}

/// A footnote reference marker found in body text.
class FootnoteRef {
  final int position;
  final int endPosition;
  final int number;

  const FootnoteRef({
    required this.position,
    required this.endPosition,
    required this.number,
  });
}

/// A part of body text — either regular text or a footnote reference.
class ForewordTextPart {
  final String text;
  final bool isFootnoteRef;
  final int? footnoteNumber;

  const ForewordTextPart({
    required this.text,
    required this.isFootnoteRef,
    this.footnoteNumber,
  });
}
