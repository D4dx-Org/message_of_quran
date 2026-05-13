/// Utility for detecting and parsing Quranic cross-references
/// (e.g. "57:20", "surah 2, note 6") in interpretation and translation text.
library;

/// A detected cross-reference in the text.
class CrossReference {
  /// The full matched text (e.g. "57:20" or "surah 2, note 6").
  final String matchedText;

  /// The referenced surah number (1–114).
  final int surahNumber;

  /// The referenced ayah number, if available.
  final int? ayahNumber;

  /// The referenced footnote/note number, if available.
  final int? noteNumber;

  const CrossReference({
    required this.matchedText,
    required this.surahNumber,
    this.ayahNumber,
    this.noteNumber,
  });
}

/// A segment of parsed text — either plain text or a cross-reference.
class TextSegment {
  final String text;
  final CrossReference? crossReference;

  const TextSegment.plain(this.text) : crossReference = null;
  const TextSegment.reference(this.text, this.crossReference);

  bool get isCrossReference => crossReference != null;
}

/// Parses [text] and splits it into [TextSegment]s, detecting Quranic
/// cross-references like "57:20", "surah 2, note 6", "note 3 on 2:14", etc.
///
/// [currentSurahNumber] is used for same-surah references like "note 4 above".
List<TextSegment> parseForCrossReferences(String text, int currentSurahNumber) {
  if (text.isEmpty) return [TextSegment.plain(text)];

  // Collect all matches with their positions, ordered by specificity.
  final matches = <_RangedMatch>[];

  // 1. "note N on N:N" — e.g. "note 3 on 2:14"
  for (final m in _noteOnPattern.allMatches(text)) {
    final surah = int.tryParse(m.group(2)!);
    final ayah = int.tryParse(m.group(3)!);
    final note = int.tryParse(m.group(1)!);
    if (surah != null && surah >= 1 && surah <= 114) {
      matches.add(_RangedMatch(
        start: m.start,
        end: m.end,
        ref: CrossReference(
          matchedText: m.group(0)!,
          surahNumber: surah,
          ayahNumber: ayah,
          noteNumber: note,
        ),
      ));
    }
  }

  // 2. "surah N, note N" — e.g. "surah 2, note 6"
  for (final m in _surahNotePattern.allMatches(text)) {
    final surah = int.tryParse(m.group(1)!);
    final note = int.tryParse(m.group(2)!);
    if (surah != null && surah >= 1 && surah <= 114) {
      if (!_overlaps(matches, m.start, m.end)) {
        matches.add(_RangedMatch(
          start: m.start,
          end: m.end,
          ref: CrossReference(
            matchedText: m.group(0)!,
            surahNumber: surah,
            noteNumber: note,
          ),
        ));
      }
    }
  }

  // 3. "surah N, verse(s) N(-N)" — e.g. "surah 2, verse 14"
  for (final m in _surahVersePattern.allMatches(text)) {
    final surah = int.tryParse(m.group(1)!);
    final verse = int.tryParse(m.group(2)!);
    if (surah != null && surah >= 1 && surah <= 114) {
      if (!_overlaps(matches, m.start, m.end)) {
        matches.add(_RangedMatch(
          start: m.start,
          end: m.end,
          ref: CrossReference(
            matchedText: m.group(0)!,
            surahNumber: surah,
            ayahNumber: verse,
          ),
        ));
      }
    }
  }

  // 4. "N:N" — e.g. "57:20", "2:255"
  for (final m in _surahAyahPattern.allMatches(text)) {
    final surah = int.tryParse(m.group(1)!);
    final ayah = int.tryParse(m.group(2)!);
    if (surah != null && surah >= 1 && surah <= 114 && ayah != null) {
      if (!_overlaps(matches, m.start, m.end)) {
        matches.add(_RangedMatch(
          start: m.start,
          end: m.end,
          ref: CrossReference(
            matchedText: m.group(0)!,
            surahNumber: surah,
            ayahNumber: ayah,
          ),
        ));
      }
    }
  }

  // 5. "note(s) N above/below" — same-surah note reference
  for (final m in _noteAbovePattern.allMatches(text)) {
    final note = int.tryParse(m.group(1)!);
    if (note != null) {
      if (!_overlaps(matches, m.start, m.end)) {
        matches.add(_RangedMatch(
          start: m.start,
          end: m.end,
          ref: CrossReference(
            matchedText: m.group(0)!,
            surahNumber: currentSurahNumber,
            noteNumber: note,
          ),
        ));
      }
    }
  }

  if (matches.isEmpty) return [TextSegment.plain(text)];

  // Sort by position
  matches.sort((a, b) => a.start.compareTo(b.start));

  // Build segments
  final segments = <TextSegment>[];
  int lastEnd = 0;
  for (final m in matches) {
    if (m.start > lastEnd) {
      segments.add(TextSegment.plain(text.substring(lastEnd, m.start)));
    }
    segments.add(TextSegment.reference(m.ref.matchedText, m.ref));
    lastEnd = m.end;
  }
  if (lastEnd < text.length) {
    segments.add(TextSegment.plain(text.substring(lastEnd)));
  }

  return segments;
}

// ─── Regex patterns ───

/// "note 3 on 2:14"
final _noteOnPattern = RegExp(
  r'note\s+(\d+)\s+on\s+(\d{1,3})\s*:\s*(\d{1,3})',
  caseSensitive: false,
);

/// "surah 2, note 6" or "surah 2 note 6"
final _surahNotePattern = RegExp(
  r'surah\s+(\d{1,3})\s*,?\s*note\s+(\d+)',
  caseSensitive: false,
);

/// "surah 2, verse 14" or "surah 2, verses 14-16"
final _surahVersePattern = RegExp(
  r'surah\s+(\d{1,3})\s*,?\s*verses?\s+(\d+)',
  caseSensitive: false,
);

/// "57:20" or "2:255" — surah:ayah format.
/// Guards: not preceded/followed by another digit to avoid false matches
/// with time formats, version numbers, etc.
final _surahAyahPattern = RegExp(
  r'(?<!\d)(\d{1,3})\s*:\s*(\d{1,3})(?!\d)',
);

/// "note 4 above" or "notes 3 and 4 above" — same-surah note reference.
/// We capture the first note number.
final _noteAbovePattern = RegExp(
  r'notes?\s+(\d+)\s+(?:above|below)',
  caseSensitive: false,
);

// ─── Helpers ───

class _RangedMatch {
  final int start;
  final int end;
  final CrossReference ref;
  const _RangedMatch({
    required this.start,
    required this.end,
    required this.ref,
  });
}

/// Check if [start]-[end] overlaps with any existing match.
bool _overlaps(List<_RangedMatch> existing, int start, int end) {
  for (final m in existing) {
    if (start < m.end && end > m.start) return true;
  }
  return false;
}
