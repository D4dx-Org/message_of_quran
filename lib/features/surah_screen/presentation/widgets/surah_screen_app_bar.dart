import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/utils/surah_place_localizer.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

String _resolveOrdinalLabel(String ordinalLabel, int surahNumber) {
  final trimmed = ordinalLabel.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }
  return _ordinalWord(surahNumber);
}

String _malayalamCardinalWord(int value) {
  const words = <String>[
    '', // 0 (unused)
    'ഒന്ന്', // 1
    'രണ്ട്', // 2
    'മൂന്ന്', // 3
    'നാല്', // 4
    'അഞ്ച്', // 5
    'ആറ്', // 6
    'ഏഴ്', // 7
    'എട്ട്', // 8
    'ഒൻപത്', // 9
    'പത്ത്', // 10
    'പതിനൊന്ന്', // 11
    'പന്ത്രണ്ട്', // 12
    'പതിമൂന്ന്', // 13
    'പതിനാല്', // 14
    'പതിനഞ്ച്', // 15
    'പതിനാറ്', // 16
    'പതിനേഴ്', // 17
    'പതിനെട്ട്', // 18
    'പത്തൊൻപത്', // 19
    'ഇരുപത്', // 20
    'ഇരുപത്തിയൊന്ന്', // 21
    'ഇരുപത്തിരണ്ട്', // 22
    'ഇരുപത്തിമൂന്ന്', // 23
    'ഇരുപത്തിനാല്', // 24
    'ഇരുപത്തഞ്ച്', // 25
    'ഇരുപത്തിയാറ്', // 26
    'ഇരുപത്തിയേഴ്', // 27
    'ഇരുപത്തിയെട്ട്', // 28
    'ഇരുപത്തൊൻപത്', // 29
    'മുപ്പത്', // 30
    'മുപ്പത്തിയൊന്ന്', // 31
    'മുപ്പത്തിരണ്ട്', // 32
    'മുപ്പത്തിമൂന്ന്', // 33
    'മുപ്പത്തിനാല്', // 34
    'മുപ്പത്തഞ്ച്', // 35
    'മുപ്പത്തിയാറ്', // 36
    'മുപ്പത്തിയേഴ്', // 37
    'മുപ്പത്തിയെട്ട്', // 38
    'മുപ്പത്തൊൻപത്', // 39
    'നാല്പത്', // 40
    'നാല്പത്തിയൊന്ന്', // 41
    'നാല്പത്തിരണ്ട്', // 42
    'നാല്പത്തിമൂന്ന്', // 43
    'നാല്പത്തിനാല്', // 44
    'നാല്പത്തഞ്ച്', // 45
    'നാല്പത്തിയാറ്', // 46
    'നാല്പത്തിയേഴ്', // 47
    'നാല്പത്തിയെട്ട്', // 48
    'നാല്പത്തൊൻപത്', // 49
    'അമ്പത്', // 50
    'അമ്പത്തിയൊന്ന്', // 51
    'അമ്പത്തിരണ്ട്', // 52
    'അമ്പത്തിമൂന്ന്', // 53
    'അമ്പത്തിനാല്', // 54
    'അമ്പത്തഞ്ച്', // 55
    'അമ്പത്തിയാറ്', // 56
    'അമ്പത്തിയേഴ്', // 57
    'അമ്പത്തിയെട്ട്', // 58
    'അമ്പത്തൊൻപത്', // 59
    'അറുപത്', // 60
    'അറുപത്തിയൊന്ന്', // 61
    'അറുപത്തിരണ്ട്', // 62
    'അറുപത്തിമൂന്ന്', // 63
    'അറുപത്തിനാല്', // 64
    'അറുപത്തഞ്ച്', // 65
    'അറുപത്തിയാറ്', // 66
    'അറുപത്തിയേഴ്', // 67
    'അറുപത്തിയെട്ട്', // 68
    'അറുപത്തൊൻപത്', // 69
    'എഴുപത്', // 70
    'എഴുപത്തിയൊന്ന്', // 71
    'എഴുപത്തിരണ്ട്', // 72
    'എഴുപത്തിമൂന്ന്', // 73
    'എഴുപത്തിനാല്', // 74
    'എഴുപത്തഞ്ച്', // 75
    'എഴുപത്തിയാറ്', // 76
    'എഴുപത്തിയേഴ്', // 77
    'എഴുപത്തിയെട്ട്', // 78
    'എഴുപത്തൊൻപത്', // 79
    'എൺപത്', // 80
    'എൺപത്തിയൊന്ന്', // 81
    'എൺപത്തിരണ്ട്', // 82
    'എൺപത്തിമൂന്ന്', // 83
    'എൺപത്തിനാല്', // 84
    'എൺപത്തഞ്ച്', // 85
    'എൺപത്തിയാറ്', // 86
    'എൺപത്തിയേഴ്', // 87
    'എൺപത്തിയെട്ട്', // 88
    'എൺപത്തൊൻപത്', // 89
    'തൊണ്ണൂറ്', // 90
    'തൊണ്ണൂറ്റിയൊന്ന്', // 91
    'തൊണ്ണൂറ്റിരണ്ട്', // 92
    'തൊണ്ണൂറ്റിമൂന്ന്', // 93
    'തൊണ്ണൂറ്റിനാല്', // 94
    'തൊണ്ണൂറ്റഞ്ച്', // 95
    'തൊണ്ണൂറ്റിയാറ്', // 96
    'തൊണ്ണൂറ്റിയേഴ്', // 97
    'തൊണ്ണൂറ്റിയെട്ട്', // 98
    'തൊണ്ണൂറ്റൊൻപത്', // 99
    'നൂറ്', // 100
    'നൂറ്റിയൊന്ന്', // 101
    'നൂറ്റിരണ്ട്', // 102
    'നൂറ്റിമൂന്ന്', // 103
    'നൂറ്റിനാല്', // 104
    'നൂറ്റഞ്ച്', // 105
    'നൂറ്റിയാറ്', // 106
    'നൂറ്റിയേഴ്', // 107
    'നൂറ്റിയെട്ട്', // 108
    'നൂറ്റൊൻപത്', // 109
    'നൂറ്റിപ്പത്ത്', // 110
    'നൂറ്റിപ്പതിനൊന്ന്', // 111
    'നൂറ്റിപ്പന്ത്രണ്ട്', // 112
    'നൂറ്റിപ്പതിമൂന്ന്', // 113
    'നൂറ്റിപ്പതിനാല്', // 114
  ];
  if (value > 0 && value < words.length) return words[value];
  return value.toString();
}

String _ordinalWord(int value) {
  if (value <= 0) {
    return value.toString();
  }

  const firstOrdinals = <String>[
    '',
    'First',
    'Second',
    'Third',
    'Fourth',
    'Fifth',
    'Sixth',
    'Seventh',
    'Eighth',
    'Ninth',
    'Tenth',
    'Eleventh',
    'Twelfth',
    'Thirteenth',
    'Fourteenth',
    'Fifteenth',
    'Sixteenth',
    'Seventeenth',
    'Eighteenth',
    'Nineteenth',
  ];
  const tensWords = <int, String>{
    20: 'Twenty',
    30: 'Thirty',
    40: 'Forty',
    50: 'Fifty',
    60: 'Sixty',
    70: 'Seventy',
    80: 'Eighty',
    90: 'Ninety',
  };
  const tensOrdinals = <int, String>{
    20: 'Twentieth',
    30: 'Thirtieth',
    40: 'Fortieth',
    50: 'Fiftieth',
    60: 'Sixtieth',
    70: 'Seventieth',
    80: 'Eightieth',
    90: 'Ninetieth',
  };

  if (value < firstOrdinals.length) {
    return firstOrdinals[value];
  }
  if (value < 100) {
    final tens = (value ~/ 10) * 10;
    final units = value % 10;
    if (units == 0) {
      return tensOrdinals[tens] ?? value.toString();
    }
    return '${tensWords[tens]}-${firstOrdinals[units]}';
  }
  if (value == 100) {
    return 'One Hundredth';
  }
  if (value < 200) {
    return 'One Hundred ${_ordinalWord(value - 100)}';
  }
  return value.toString();
}

String _surahHeaderTitle({
  required bool isMalayalam,
  required String ordinalLabel,
  required int surahNumber,
}) {
  if (isMalayalam) {
    return 'അധ്യായം ${_malayalamCardinalWord(surahNumber)}';
  }

  return 'The ${_resolveOrdinalLabel(ordinalLabel, surahNumber)} Surah';
}

String _surahDisplayNameLine({
  required bool isMalayalam,
  required String surahName,
  required String surahTranslation,
  required String malayalamName,
  required int surahNumber,
}) {
  return formatSurahDisplayNameLine(
    isMalayalam: isMalayalam,
    surahName: surahName,
    surahTranslation: surahTranslation,
    malayalamName: malayalamName,
    surahNumber: surahNumber,
  );
}

String _surahPlaceLine(
  String place, {
  required bool isMalayalam,
  required int surahNumber,
}) {
  if (!isMalayalam) {
    return localizeSurahPeriodLabel(place, isMalayalam: false);
  }

  switch (resolveSurahPlaceKind(place)) {
    case SurahPlaceKind.makkah:
      return 'മക്കാ കാലഘട്ടം';
    case SurahPlaceKind.madinah:
      return localizeSurahMadinahDisplayLabel(
        place,
        isMalayalam: true,
        surahNumber: surahNumber,
        fallback: 'അവതരണം മദീനയിൽ',
      );
    case null:
      return localizeSurahPeriodLabel(place, isMalayalam: true);
  }
}

/// Surah info strip with book-style content ordering and nav arrows.
class SurahInfoStrip extends StatelessWidget {
  final String surahName;
  final String surahTranslation;
  final String malayalamName;
  final String place;
  final String ordinalLabel;
  final int surahNumber;
  final bool isMalayalam;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool showPrevious;
  final bool showNext;

  const SurahInfoStrip({
    super.key,
    required this.surahName,
    required this.surahTranslation,
    this.malayalamName = '',
    required this.place,
    required this.ordinalLabel,
    required this.surahNumber,
    this.isMalayalam = false,
    this.onPrevious,
    this.onNext,
    this.showPrevious = true,
    this.showNext = true,
  });

  @override
  Widget build(BuildContext context) {
    final headerTitle = _surahHeaderTitle(
      isMalayalam: isMalayalam,
      ordinalLabel: ordinalLabel,
      surahNumber: surahNumber,
    );
    final nameLine = _surahDisplayNameLine(
      isMalayalam: isMalayalam,
      surahName: surahName,
      surahTranslation: surahTranslation,
      malayalamName: malayalamName,
      surahNumber: surahNumber,
    );
    final placeLine = _surahPlaceLine(
      place,
      isMalayalam: isMalayalam,
      surahNumber: surahNumber,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.appThemePrimary, Color(0xFF123B69)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.appThemePrimary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _navBtn(Icons.arrow_back_ios_new, showPrevious, onPrevious),
          const SizedBox(width: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    headerTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.88),
                      letterSpacing: 0.4,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        nameLine,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.15,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    placeLine,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          _navBtn(Icons.arrow_forward_ios_rounded, showNext, onNext),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, bool visible, VoidCallback? onPressed) {
    return Visibility(
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      visible: visible,
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: 16,
          color: Colors.white.withValues(alpha: 0.9),
          style: IconButton.styleFrom(
            shape: CircleBorder(
              side: BorderSide(
                color: AppTheme.appIconTheme.withValues(alpha: 0.4),
              ),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
          ),
          icon: Icon(icon),
        ),
      ),
    );
  }
}

/// Sliver wrapper for continuous scroll mode.
class SurahScreenAppBar extends StatelessWidget {
  const SurahScreenAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    return SliverToBoxAdapter(
      child: Consumer<SurahProvider>(
        builder: (context, sp, _) {
          if (sp.surahList.isEmpty || sp.index >= sp.surahList.length) {
            return const SizedBox.shrink();
          }
          final surah = sp.surahList[sp.index];
          return SurahInfoStrip(
            surahName: surah.name,
            surahTranslation: surah.description,
            malayalamName: surah.malayalamName,
            place: surah.place,
            ordinalLabel: surah.ordinalLabel,
            surahNumber: surah.surahNumber,
            isMalayalam: isMalayalam,
            showPrevious: sp.index < sp.surahList.length - 1,
            showNext: sp.index > 0,
            onPrevious: () => sp.onSwipe(false),
            onNext: () => sp.onSwipe(true),
          );
        },
      ),
    );
  }
}
