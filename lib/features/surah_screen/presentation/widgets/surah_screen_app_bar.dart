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
    return 'അധ്യായം $surahNumber';
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
