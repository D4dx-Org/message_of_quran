import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/mushaf/services/qcf_font_service.dart';
import 'package:the_message_of_the_quran/features/mushaf/utils/surah_unicode.dart';

/// A surah's calligraphic name from the `sura_names` font, with its stroke
/// weight evened out.
///
/// The font (the same file quran.com ships) was not drawn to one weight: by
/// typical stroke, the names run from a sixth lighter than the median to a
/// third heavier, and the two heaviest are the first two in the book. There
/// is no lighter copy of the font to switch to, so the correction is done
/// here: each glyph is drawn with a hairline overlay sized to its measured
/// excess — in the background colour to trim a heavy glyph, in the text
/// colour to fatten a light one — so the whole list sits at one weight.
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

  /// Typical stroke half-width of each glyph, in hundredths of a pixel when
  /// rendered at 200px. Measured by eroding the glyph one pixel at a time and
  /// noting when half its ink is gone — the thickness of its ordinary strokes,
  /// not of its thickest knot, which is what an earlier max-stroke measure
  /// tracked and why it thinned Al-Humazah (one fat dot, thin letters) into
  /// something that read as broken.
  static const Map<int, int> _strokeAt200 = {
    1: 221,
    2: 239,
    3: 193,
    4: 175,
    5: 176,
    6: 175,
    7: 177,
    8: 167,
    9: 167,
    10: 156,
    11: 197,
    12: 154,
    13: 189,
    14: 173,
    15: 193,
    16: 193,
    17: 169,
    18: 182,
    19: 166,
    20: 161,
    21: 190,
    22: 182,
    23: 190,
    24: 180,
    25: 177,
    26: 150,
    27: 169,
    28: 163,
    29: 166,
    30: 153,
    31: 168,
    32: 174,
    33: 174,
    34: 164,
    35: 173,
    36: 160,
    37: 165,
    38: 165,
    39: 183,
    40: 157,
    41: 178,
    42: 179,
    43: 178,
    44: 172,
    45: 170,
    46: 201,
    47: 189,
    48: 193,
    49: 206,
    50: 172,
    51: 158,
    52: 178,
    53: 178,
    54: 187,
    55: 192,
    56: 194,
    57: 201,
    58: 187,
    59: 176,
    60: 181,
    61: 183,
    62: 184,
    63: 173,
    64: 171,
    65: 166,
    66: 171,
    67: 191,
    68: 175,
    69: 192,
    70: 191,
    71: 199,
    72: 180,
    73: 172,
    74: 170,
    75: 200,
    76: 181,
    77: 177,
    78: 186,
    79: 168,
    80: 167,
    81: 189,
    82: 178,
    83: 194,
    84: 181,
    85: 188,
    86: 170,
    87: 183,
    88: 166,
    89: 197,
    90: 181,
    91: 178,
    92: 179,
    93: 200,
    94: 186,
    95: 176,
    96: 183,
    97: 188,
    98: 169,
    99: 175,
    100: 172,
    101: 174,
    102: 181,
    103: 179,
    104: 184,
    105: 177,
    106: 182,
    107: 195,
    108: 186,
    109: 183,
    110: 177,
    111: 182,
    112: 183,
    113: 177,
    114: 160,
  };

  /// The median of the table; every glyph is pulled towards it.
  static const int _target = 178;

  /// How far this glyph's stroke sits from the median, as a fraction of the
  /// median: +0.34 is a third heavier, -0.16 a sixth lighter. Exposed for
  /// tests.
  static double weightRatio(int surahNumber) =>
      ((_strokeAt200[surahNumber] ?? _target) - _target) / _target;

  /// Width of the correcting stroke at [fontSize]. Calibrated on device: a
  /// glyph a third heavier than the median needed roughly a pixel of trim at
  /// 30px to sit level with its neighbours, so the scale is a tenth of the
  /// font size per 100% of excess. Positive ratios are trimmed, negative
  /// ones fattened, so the sign of [weightRatio] picks the overlay colour.
  static double overlayWidth(int surahNumber, double fontSize) =>
      weightRatio(surahNumber).abs() * fontSize / 10;

  @override
  Widget build(BuildContext context) {
    // sura_names is registered on demand, and its glyphs live in the private
    // use area: with the font missing the row would show empty boxes rather
    // than a readable fallback, so hold the space until it is in.
    return FutureBuilder<void>(
      future: QcfFontService.instance.ensureFamily('sura_names'),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(height: fontSize * (height ?? 1.2));
        }
        return _buildGlyph(context);
      },
    );
  }

  Widget _buildGlyph(BuildContext context) {
    final glyph = SurahUnicodeData.getSurahNameUnicode(surahNumber);
    final ratio = weightRatio(surahNumber);
    final width = overlayWidth(surahNumber, fontSize);

    final fill = Text(
      glyph,
      style: TextStyle(
        fontFamily: 'sura_names',
        fontSize: fontSize,
        height: height,
        color: color,
      ),
    );
    // Below a twentieth of a pixel the overlay is invisible; skip the Stack.
    if (width < 0.05) return fill;

    final overlay = Text(
      glyph,
      style: TextStyle(
        fontFamily: 'sura_names',
        fontSize: fontSize,
        height: height,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round
          ..color = ratio > 0 ? background : color,
      ),
    );

    return Stack(alignment: Alignment.center, children: [fill, overlay]);
  }
}
