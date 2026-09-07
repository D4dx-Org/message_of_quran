import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/mushaf/utils/surah_unicode.dart';

/// A surah's calligraphic name from the `sura_names` font, with its stroke
/// weight evened out.
///
/// The font (the same file quran.com ships) was not drawn to one weight: the
/// outlines for Al-Fatihah, Al-Baqarah and a few dozen others are noticeably
/// heavier than the rest, so a list of names reads as a mix of bold and
/// regular. There is no lighter copy of the font to switch to, so the
/// correction is done here: each glyph's stroke was measured, and the heavy
/// ones are drawn with a hairline overlay in the background colour that trims
/// them back to the median. Light glyphs are left as drawn — thickening them
/// made them look heavier than the trimmed ones, and a light name never read
/// as wrong the way a bold one did.
class SurahNameGlyph extends StatelessWidget {
  const SurahNameGlyph({
    super.key,
    required this.surahNumber,
    required this.fontSize,
    required this.color,
    required this.background,
    this.height,
  });

  final int surahNumber;
  final double fontSize;
  final Color color;

  /// The colour behind the glyph; a heavy glyph is trimmed by stroking its
  /// edge in this colour.
  final Color background;
  final double? height;

  /// Maximum stroke thickness of each glyph, measured as the number of
  /// one-pixel erosions needed to make it vanish when rendered at 200px, so
  /// roughly half the stroke width in pixels at that size.
  static const Map<int, int> _strokeAt200 = {
    1: 11,
    2: 11,
    3: 10,
    4: 7,
    5: 9,
    6: 9,
    7: 8,
    8: 8,
    9: 8,
    10: 7,
    11: 8,
    12: 8,
    13: 9,
    14: 8,
    15: 10,
    16: 10,
    17: 7,
    18: 11,
    19: 9,
    20: 7,
    21: 8,
    22: 9,
    23: 9,
    24: 8,
    25: 9,
    26: 9,
    27: 9,
    28: 8,
    29: 8,
    30: 7,
    31: 9,
    32: 10,
    33: 10,
    34: 7,
    35: 7,
    36: 7,
    37: 8,
    38: 9,
    39: 8,
    40: 8,
    41: 9,
    42: 9,
    43: 9,
    44: 10,
    45: 10,
    46: 9,
    47: 11,
    48: 10,
    49: 10,
    50: 7,
    51: 7,
    52: 8,
    53: 10,
    54: 10,
    55: 11,
    56: 10,
    57: 11,
    58: 10,
    59: 9,
    60: 11,
    61: 9,
    62: 10,
    63: 9,
    64: 9,
    65: 8,
    66: 9,
    67: 9,
    68: 10,
    69: 10,
    70: 10,
    71: 9,
    72: 10,
    73: 8,
    74: 8,
    75: 8,
    76: 10,
    77: 10,
    78: 8,
    79: 9,
    80: 9,
    81: 8,
    82: 9,
    83: 10,
    84: 10,
    85: 9,
    86: 9,
    87: 9,
    88: 10,
    89: 10,
    90: 8,
    91: 9,
    92: 7,
    93: 10,
    94: 10,
    95: 7,
    96: 9,
    97: 9,
    98: 7,
    99: 7,
    100: 9,
    101: 9,
    102: 8,
    103: 9,
    104: 12,
    105: 8,
    106: 8,
    107: 10,
    108: 9,
    109: 8,
    110: 9,
    111: 9,
    112: 9,
    113: 9,
    114: 7,
  };

  /// The weight the heavy glyphs are trimmed down to. The font's median is 9,
  /// but on a phone screen the heavy names still read a step bolder than the
  /// rest after trimming to 9, so aim one unit lighter; the 8-and-below
  /// glyphs are untouched either way.
  static const int _target = 8;

  /// How far this glyph's stroke sits from the target, in the same erosion
  /// units. Exposed for tests.
  static int strokeDelta(int surahNumber) =>
      (_strokeAt200[surahNumber] ?? _target) - _target;

  /// Width of the trimming stroke needed to bring a heavy glyph down to the
  /// target at [fontSize]: an erosion at 200px is half a pixel of stroke per
  /// side, so one unit of delta is `fontSize / 100` of full stroke width.
  /// Zero for glyphs at or below the target.
  static double overlayWidth(int surahNumber, double fontSize) {
    final delta = strokeDelta(surahNumber);
    return delta > 0 ? delta * fontSize / 100 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final glyph = SurahUnicodeData.getSurahNameUnicode(surahNumber);
    final delta = strokeDelta(surahNumber);

    final fill = Text(
      glyph,
      style: TextStyle(
        fontFamily: 'sura_names',
        fontSize: fontSize,
        height: height,
        color: color,
      ),
    );
    if (delta <= 0) return fill;

    final overlay = Text(
      glyph,
      style: TextStyle(
        fontFamily: 'sura_names',
        fontSize: fontSize,
        height: height,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = overlayWidth(surahNumber, fontSize)
          ..strokeJoin = StrokeJoin.round
          ..color = background,
      ),
    );

    return Stack(alignment: Alignment.center, children: [fill, overlay]);
  }
}
