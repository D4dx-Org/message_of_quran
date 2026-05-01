/// A single aya segment within a Mushaf line.
///
/// A line from `t_mushafpages` can contain multiple ayas separated by `▌`.
/// Each segment becomes one [AyaSegment] that maps to a single Text widget.
class AyaSegment {
  const AyaSegment({required this.text, required this.isContinuation});

  /// Display-ready glyph text (already reversed and trimmed).
  final String text;

  /// `true` when the aya continues on the next line (had `▼` marker).
  final bool isContinuation;
}

/// Utilities for processing the raw glyph data stored in `t_mushafpages`.
class MushafTextUtils {
  MushafTextUtils._();

  /// Reverse a string (the DB stores glyph data in reverse order).
  static String reverseText(String input) {
    return String.fromCharCodes(input.runes.toList().reversed);
  }

  /// Parse a raw line from `t_mushafpages.data` into a list of aya segments.
  static List<AyaSegment> parseLine(
    String rawData, {
    bool isHeadingOrBismillah = false,
  }) {
    if (rawData.isEmpty) return const [];

    if (isHeadingOrBismillah) {
      final reversed = reverseText(rawData).replaceAll('▌', '').trim();
      return [AyaSegment(text: reversed, isContinuation: false)];
    }

    final parts = rawData.split('▌');
    final segments = <AyaSegment>[];

    if (parts.length > 1) {
      for (var j = parts.length - 1; j >= 0; j--) {
        var piece = parts[j];
        if (piece.isEmpty) continue;

        final hasContinuation = piece.contains('▼');
        if (hasContinuation) piece = piece.replaceAll('▼', '');

        final reversed = reverseText(piece).replaceAll('▌', '').trim();
        if (reversed.isEmpty) continue;

        final displayText = j == 0 ? '$reversed\u0020' : reversed;
        segments.add(
          AyaSegment(text: displayText, isContinuation: hasContinuation),
        );
      }
    } else {
      var piece = rawData;
      final hasContinuation = piece.contains('▼');
      if (hasContinuation) piece = piece.replaceAll('▼', '');

      final reversed = reverseText(piece).replaceAll('▌', '').trim();
      if (reversed.isNotEmpty) {
        segments.add(
          AyaSegment(text: '$reversed\u0020', isContinuation: hasContinuation),
        );
      }
    }

    return segments;
  }
}
