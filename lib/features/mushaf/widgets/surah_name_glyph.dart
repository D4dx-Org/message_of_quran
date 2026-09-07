import 'package:flutter/material.dart';

/// A surah's Arabic name, set as text in the Mus'haf header font.
///
/// The list used to draw each name from `sura_names.ttf`, a font of 114
/// hand-drawn calligraphic glyphs. They were never one weight: strokes ran
/// from a sixth lighter than the median to a third heavier, and beyond the
/// strokes the designs differ in mass — some names dense with diacritics,
/// others sparse — so no per-glyph correction could make the column read as
/// level. Setting the names as ordinary text in a single font does: every
/// name shares one outline weight, one size and one baseline, which is the
/// consistency the reader asked for. Amiri is the reader's default Qur'an
/// face, a Naskh drawn to one weight, and the only bundled calligraphic font
/// that carries the full Arabic alphabet (QCF_BSML holds marks and
/// presentation forms only, and renders the letters as boxes).
class SurahNameGlyph extends StatelessWidget {
  const SurahNameGlyph({
    super.key,
    required this.surahNumber,
    required this.fontSize,
    required this.color,
    this.height,
  });

  final int surahNumber;
  final double fontSize;
  final Color color;
  final double? height;

  /// The name of each surah without the leading "سورة", as held in the
  /// bundled database's `surahs.arabic_name`.
  static const Map<int, String> arabicNames = {
    1: 'الفاتحة',
    2: 'البقرة',
    3: 'آل عمران',
    4: 'النساء',
    5: 'المائدة',
    6: 'الأنعام',
    7: 'الأعراف',
    8: 'الأنفال',
    9: 'التوبة',
    10: 'يونس',
    11: 'هود',
    12: 'يوسف',
    13: 'الرعد',
    14: 'إبراهيم',
    15: 'الحجر',
    16: 'النحل',
    17: 'الإسراء',
    18: 'الكهف',
    19: 'مريم',
    20: 'طه',
    21: 'الأنبياء',
    22: 'الحج',
    23: 'المؤمنون',
    24: 'النور',
    25: 'الفرقان',
    26: 'الشعراء',
    27: 'النمل',
    28: 'القصص',
    29: 'العنكبوت',
    30: 'الروم',
    31: 'لقمان',
    32: 'السجدة',
    33: 'الأحزاب',
    34: 'سبأ',
    35: 'فاطر',
    36: 'يس',
    37: 'الصافات',
    38: 'ص',
    39: 'الزمر',
    40: 'غافر',
    41: 'فصلت',
    42: 'الشورى',
    43: 'الزخرف',
    44: 'الدخان',
    45: 'الجاثية',
    46: 'الأحقاف',
    47: 'محمد',
    48: 'الفتح',
    49: 'الحجرات',
    50: 'ق',
    51: 'الذاريات',
    52: 'الطور',
    53: 'النجم',
    54: 'القمر',
    55: 'الرحمن',
    56: 'الواقعة',
    57: 'الحديد',
    58: 'المجادلة',
    59: 'الحشر',
    60: 'الممتحنة',
    61: 'الصف',
    62: 'الجمعة',
    63: 'المنافقون',
    64: 'التغابن',
    65: 'الطلاق',
    66: 'التحريم',
    67: 'الملك',
    68: 'القلم',
    69: 'الحاقة',
    70: 'المعارج',
    71: 'نوح',
    72: 'الجن',
    73: 'المزمل',
    74: 'المدثر',
    75: 'القيامة',
    76: 'الإنسان',
    77: 'المرسلات',
    78: 'النبأ',
    79: 'النازعات',
    80: 'عبس',
    81: 'التكوير',
    82: 'الانفطار',
    83: 'المطففين',
    84: 'الانشقاق',
    85: 'البروج',
    86: 'الطارق',
    87: 'الأعلى',
    88: 'الغاشية',
    89: 'الفجر',
    90: 'البلد',
    91: 'الشمس',
    92: 'الليل',
    93: 'الضحى',
    94: 'الانشراح',
    95: 'التين',
    96: 'العلق',
    97: 'القدر',
    98: 'البينة',
    99: 'الزلزلة',
    100: 'العاديات',
    101: 'القارعة',
    102: 'التكاثر',
    103: 'العصر',
    104: 'الهمزة',
    105: 'الفيل',
    106: 'قريش',
    107: 'الماعون',
    108: 'الكوثر',
    109: 'الكافرون',
    110: 'النصر',
    111: 'المسد',
    112: 'الإخلاص',
    113: 'الفلق',
    114: 'الناس',
  };

  static String nameOf(int surahNumber) => arabicNames[surahNumber] ?? '';

  @override
  Widget build(BuildContext context) {
    // Shrinks a long name to the slot it is given rather than spilling past
    // the card edge; short names keep their full size. Callers in a Row give
    // it a Flexible so the slot has a bound to shrink into.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: Text(
        nameOf(surahNumber),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: fontSize,
          height: height,
          color: color,
        ),
      ),
    );
  }
}
