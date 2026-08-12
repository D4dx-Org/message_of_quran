import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/utils/surah_place_localizer.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

const _kMakkahIcon = 'assets/icons/revamp/makkah_icon.svg';
const _kMadinahIcon = 'assets/icons/revamp/madeena_icon.svg';

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

String _surahPlaceLine(String place, {required bool isMalayalam}) {
  if (!isMalayalam) {
    return localizeSurahPeriodLabel(place, isMalayalam: false);
  }

  final trimmedPlace = place.trim();
  if (trimmedPlace.isNotEmpty) {
    return trimmedPlace;
  }

  return localizeSurahPeriodLabel(place, isMalayalam: true);
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
  final double horizontalMargin;
  final Widget? footer;
  final Widget? trailingActions;

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
    this.horizontalMargin = 12,
    this.footer,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    const useDesktopWebSurface = kIsWeb;
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
    final placeLine = _surahPlaceLine(place, isMalayalam: isMalayalam);
    final primaryTextColor = useDesktopWebSurface
        ? (isDarkMode ? Colors.white : AppTheme.appThemePrimary)
        : Colors.white;
    final secondaryTextColor = useDesktopWebSurface
        ? (isDarkMode ? Colors.white70 : Colors.grey[600]!)
        : Colors.white.withValues(alpha: 0.86);
    final stripDecoration = useDesktopWebSurface
        ? BoxDecoration(
            color: isDarkMode ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(
              AppTheme.desktopContentCardRadius,
            ),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.10)
                  : (theme.dividerTheme.color ??
                        theme.colorScheme.outlineVariant),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.12 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          )
        : BoxDecoration(
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
          );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: stripDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _navBtn(
                context,
                Icons.arrow_back_ios_new,
                showPrevious,
                onPrevious,
                useDesktopWebSurface: useDesktopWebSurface,
                tooltip: 'Next Surah',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        headerTitle,
                        style: AppTextTheme.localizedLabel(
                          isMalayalam: isMalayalam,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                          letterSpacing: 0.4,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            nameLine,
                            style: AppTextTheme.localizedTitle(
                              isMalayalam: isMalayalam,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
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
                        style: AppTextTheme.localizedBody(
                          isMalayalam: isMalayalam,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: secondaryTextColor,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              if (trailingActions != null) ...[
                const SizedBox(width: 10),
                trailingActions!,
              ],
              const SizedBox(width: 10),
              _navBtn(
                context,
                Icons.arrow_forward_ios_rounded,
                showNext,
                onNext,
                useDesktopWebSurface: useDesktopWebSurface,
                tooltip: 'Previous Surah',
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }

  Widget _navBtn(
    BuildContext context,
    IconData icon,
    bool visible,
    VoidCallback? onPressed, {
    required bool useDesktopWebSurface,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final foregroundColor = useDesktopWebSurface
        ? (isDarkMode ? Colors.white70 : AppTheme.appThemePrimary)
        : Colors.white.withValues(alpha: 0.9);
    final borderColor = useDesktopWebSurface
        ? (isDarkMode
              ? Colors.white.withValues(alpha: 0.16)
              : AppTheme.appThemePrimary.withValues(alpha: 0.16))
        : AppTheme.appIconTheme.withValues(alpha: 0.4);
    final fillColor = useDesktopWebSurface
        ? (isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.appThemePrimary.withValues(alpha: 0.06))
        : Colors.white.withValues(alpha: 0.08);

    return Opacity(
      opacity: visible ? 1.0 : 0.3,
      child: Tooltip(
        message: tooltip ?? '',
        child: SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            onPressed: visible ? onPressed : null,
            padding: EdgeInsets.zero,
            iconSize: 16,
            color: foregroundColor,
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              backgroundColor: fillColor,
            ),
            icon: Icon(icon),
          ),
        ),
      ),
    );
  }
}

/// Sliver wrapper for continuous scroll mode.
class SurahScreenAppBar extends StatelessWidget {
  const SurahScreenAppBar({
    super.key,
    required this.arabicBlockList,
    required this.currentAyahNumber,
    required this.onAyahSelected,
    this.onPlayPressed,
    this.onInfoPressed,
    this.showStopIcon = false,
  });

  final List<ArabicBlockModel> arabicBlockList;
  final int currentAyahNumber;
  final ValueChanged<int> onAyahSelected;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onInfoPressed;
  final bool showStopIcon;

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
            trailingActions: (onPlayPressed == null && onInfoPressed == null)
                ? null
                : SurahBannerActions(
                    isMalayalam: isMalayalam,
                    onPlayPressed: onPlayPressed,
                    onInfoPressed: onInfoPressed,
                    showStopIcon: showStopIcon,
                    compact: true,
                  ),
          );
        },
      ),
    );
  }
}

class SurahBannerActions extends StatelessWidget {
  const SurahBannerActions({
    super.key,
    required this.isMalayalam,
    this.onPlayPressed,
    this.onInfoPressed,
    this.showStopIcon = false,
    this.compact = false,
  });

  final bool isMalayalam;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onInfoPressed;
  final bool showStopIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (onPlayPressed == null && onInfoPressed == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    const useDesktopWebSurface = kIsWeb;
    final iconColor = useDesktopWebSurface
        ? (isDarkMode ? Colors.white70 : AppTheme.appThemePrimary)
        : Colors.white.withValues(alpha: 0.9);
    final borderColor = useDesktopWebSurface
        ? (isDarkMode
              ? Colors.white.withValues(alpha: 0.16)
              : AppTheme.appThemePrimary.withValues(alpha: 0.16))
        : AppTheme.appIconTheme.withValues(alpha: 0.4);
    final fillColor = useDesktopWebSurface
        ? (isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.appThemePrimary.withValues(alpha: 0.06))
        : Colors.white.withValues(alpha: 0.08);

    Widget buildActionIcon({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: fillColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            side: BorderSide(color: borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            onTap: onPressed,
            child: SizedBox(
              width: compact ? 34 : 40,
              height: compact ? 34 : 40,
              child: Icon(icon, color: iconColor, size: compact ? 18 : 20),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onPlayPressed != null)
            buildActionIcon(
              icon: showStopIcon
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline_rounded,
              tooltip: showStopIcon ? 'Stop Surah' : 'Play Surah',
              onPressed: onPlayPressed!,
            ),
          if (onPlayPressed != null && onInfoPressed != null)
            const SizedBox(width: 10),
          if (onInfoPressed != null)
            buildActionIcon(
              icon: Icons.info_outline_rounded,
              tooltip: 'Surah Info',
              onPressed: onInfoPressed!,
            ),
        ],
      ),
    );
  }
}

class SurahHeaderControls extends StatelessWidget {
  const SurahHeaderControls({
    super.key,
    required this.isMalayalam,
    required this.surahList,
    required this.currentSurahNumber,
    required this.arabicBlockList,
    required this.currentAyahNumber,
    required this.onAyahSelected,
    this.onPlayPressed,
    this.onInfoPressed,
    this.showStopIcon = false,
    this.compact = false,
    this.showActions = true,
  });

  final bool isMalayalam;
  final List<SurahModel> surahList;
  final int currentSurahNumber;
  final List<ArabicBlockModel> arabicBlockList;
  final int currentAyahNumber;
  final ValueChanged<int> onAyahSelected;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onInfoPressed;
  final bool showStopIcon;
  final bool compact;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveHelper.scaleFactor(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final fieldFill = compact
        ? Colors.white.withValues(alpha: isDarkMode ? 0.10 : 0.12)
        : (isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : AppTheme.appThemePrimary.withValues(alpha: 0.05));
    final fieldBorder = compact
        ? Colors.white.withValues(alpha: 0.20)
        : (isDarkMode
              ? Colors.white.withValues(alpha: 0.14)
              : AppTheme.appThemePrimary.withValues(alpha: 0.14));
    final labelColor = compact
        ? Colors.white
        : (isDarkMode ? Colors.white70 : AppTheme.appThemePrimary);
    // Color for items inside the dropdown popup (renders on card/white background).
    final popupItemColor = isDarkMode ? Colors.white : Colors.black87;
    final itemTextStyle = AppTextTheme.localizedLabel(
      isMalayalam: isMalayalam,
      fontSize: (compact ? 10 : 13) * scale,
      fontWeight: FontWeight.w500,
      color: labelColor,
    );
    final popupItemTextStyle = itemTextStyle.copyWith(
      color: popupItemColor,
      fontSize: (compact ? 11 : 13) * scale,
      height: 1.0,
    );

    // Builds a popup item wrapped in tight vertical padding for compact rows.
    Widget popupItemChild(String text, {bool selected = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: popupItemTextStyle.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      );
    }

    final surahItems = surahList
        .map<DropdownMenuItem<int>>((surah) {
          final displayText = formatSurahListDisplayText(
            isMalayalam: isMalayalam,
            surahName: surah.name,
            surahTranslation: surah.description,
            malayalamName: surah.malayalamName,
            surahNumber: surah.surahNumber,
          );
          return DropdownMenuItem<int>(
            value: surah.surahNumber,
            child: popupItemChild(
              '${surah.surahNumber}. ${displayText.title}',
              selected: surah.surahNumber == currentSurahNumber,
            ),
          );
        })
        .toList(growable: false);

    // Parallel list of label-only widgets used by selectedItemBuilder so that
    // the closed-button label always renders in white (labelColor / itemTextStyle)
    // regardless of the black popup item style.
    final surahSelectedLabels = surahList
        .map<Widget>((surah) {
          final displayText = formatSurahListDisplayText(
            isMalayalam: isMalayalam,
            surahName: surah.name,
            surahTranslation: surah.description,
            malayalamName: surah.malayalamName,
            surahNumber: surah.surahNumber,
          );
          return Text(
            '${surah.surahNumber}. ${displayText.title}',
            overflow: TextOverflow.ellipsis,
            style: itemTextStyle,
          );
        })
        .toList(growable: false);

    // Numbers only (no "Ayah"/"Ayahs" word) — this dropdown's own chip/caption
    // already makes clear what it jumps to.
    String ayahNumberLabel(int start, int end) =>
        start == end ? '$start' : '$start – $end';

    final ayahItems = arabicBlockList
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final block = entry.value;
          final start = block.verseFrom ?? index + 1;
          final end = block.verseTo ?? index + 1;
          return DropdownMenuItem<int>(
            value: start,
            child: popupItemChild(
              ayahNumberLabel(start, end),
              selected: start == currentAyahNumber,
            ),
          );
        })
        .toList(growable: false);

    final ayahSelectedLabels = arabicBlockList
        .asMap()
        .entries
        .map<Widget>((entry) {
          final index = entry.key;
          final block = entry.value;
          final start = block.verseFrom ?? index + 1;
          final end = block.verseTo ?? index + 1;
          return Text(
            ayahNumberLabel(start, end),
            overflow: TextOverflow.ellipsis,
            style: itemTextStyle,
          );
        })
        .toList(growable: false);

    Widget buildDropdown({
      required String label,
      required int? value,
      required List<DropdownMenuItem<int>> items,
      required ValueChanged<int?> onChanged,
      List<Widget>? selectedLabels,
      bool dynamicWidth = false,
    }) {
      // DropdownButton asserts that value must be present in items when non-null.
      // Guard against empty lists or stale values during initial load.
      final safeValue =
          (value != null && items.any((item) => item.value == value))
          ? value
          : null;
      final dropdown = DecoratedBox(
        decoration: BoxDecoration(
          color: fieldFill,
          borderRadius: BorderRadius.circular(compact ? 8 : 14),
          border: Border.all(color: fieldBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: safeValue,
            hint: Text(label, style: itemTextStyle),
            // selectedItemBuilder renders the closed-button label in white
            // (itemTextStyle) while popup items keep their black popupItemTextStyle.
            selectedItemBuilder: selectedLabels != null
                ? (_) => selectedLabels
                : null,
            isExpanded: dynamicWidth ? false : !compact,
            isDense: compact,
            // null = use intrinsic item height (avoids the >=48 assertion)
            itemHeight: null,
            borderRadius: BorderRadius.circular(compact ? 8 : 14),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 14,
              vertical: compact ? 0 : 2,
            ),
            dropdownColor: theme.cardColor,
            iconEnabledColor: labelColor,
            style: itemTextStyle,
            items: items,
            onChanged: onChanged,
          ),
        ),
      );

      if (compact) {
        return dropdown;
      }

      final column = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: itemTextStyle.copyWith(
                fontSize: 11 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          dropdown,
        ],
      );

      // Shrink-wraps to content instead of stretching to fill the row/column,
      // since callers that request dynamicWidth wrap it in Expanded/stretch.
      return dynamicWidth
          ? Align(alignment: AlignmentDirectional.centerStart, child: column)
          : column;
    }

    Widget buildActionIcon({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: fieldFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 10 : 14),
            side: BorderSide(color: fieldBorder),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(compact ? 10 : 14),
            onTap: onPressed,
            child: SizedBox(
              width: compact ? 32 : 44,
              height: compact ? 32 : 44,
              child: Icon(icon, color: labelColor, size: compact ? 18 : 22),
            ),
          ),
        ),
      );
    }

    final ayahDropdown = buildDropdown(
      label: isMalayalam ? 'ആയത്ത്' : 'Ayah',
      value: currentAyahNumber,
      items: ayahItems,
      selectedLabels: ayahSelectedLabels.isNotEmpty ? ayahSelectedLabels : null,
      dynamicWidth: true,
      onChanged: (value) {
        if (value == null) return;
        onAyahSelected(value);
      },
    );

    final surahDropdown = buildDropdown(
      label: isMalayalam ? 'ജം ടു സൂറ' : 'Jump to Surah',
      value: currentSurahNumber,
      items: surahItems,
      selectedLabels: surahSelectedLabels.isNotEmpty
          ? surahSelectedLabels
          : null,
      onChanged: (value) async {
        if (value == null) return;
        await context.read<SurahProvider>().selectSurahByNumber(value);
      },
    );

    final actionButtons = <Widget>[
      if (showActions && onPlayPressed != null)
        buildActionIcon(
          icon: showStopIcon
              ? Icons.stop_circle_outlined
              : Icons.play_circle_outline_rounded,
          tooltip: showStopIcon
              ? (isMalayalam ? 'സ്റ്റോപ്പ്' : 'Stop')
              : (isMalayalam ? 'പ്ലേ' : 'Play'),
          onPressed: onPlayPressed!,
        ),
      if (showActions && onInfoPressed != null) ...[
        if (showActions && onPlayPressed != null) const SizedBox(width: 10),
        buildActionIcon(
          icon: Icons.info_outline_rounded,
          tooltip: isMalayalam ? 'വിവരം' : 'Info',
          onPressed: onInfoPressed!,
        ),
      ],
    ];

    if (width < 720) {
      if (compact) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SurahJumpButton(
              isMalayalam: isMalayalam,
              surahList: surahList,
              currentSurahNumber: currentSurahNumber,
              arabicBlockList: arabicBlockList,
              currentAyahNumber: currentAyahNumber,
              onAyahSelected: onAyahSelected,
            ),
            if (actionButtons.isNotEmpty) ...[
              const SizedBox(width: 6),
              ...actionButtons,
            ],
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ayahDropdown,
          const SizedBox(height: 10),
          surahDropdown,
          if (actionButtons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actionButtons,
            ),
          ],
        ],
      );
    }

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SurahJumpButton(
            isMalayalam: isMalayalam,
            surahList: surahList,
            currentSurahNumber: currentSurahNumber,
            arabicBlockList: arabicBlockList,
            currentAyahNumber: currentAyahNumber,
            onAyahSelected: onAyahSelected,
          ),
          if (actionButtons.isNotEmpty) ...[
            const SizedBox(width: 6),
            ...actionButtons,
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ayahDropdown,
        const SizedBox(width: 12),
        Expanded(child: surahDropdown),
        if (actionButtons.isNotEmpty) ...[
          const SizedBox(width: 12),
          Row(children: actionButtons),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SurahJumpButton — compact chip that opens the Surah/Ayah navigator sheet.
// ─────────────────────────────────────────────────────────────────────────────

/// A single compact chip shown in the app bar. Tapping it opens
/// [_SurahNavigatorSheet], which lets the user jump to any surah or ayah.
/// It is stateful so it remembers the last explicitly-jumped-to ayah and
/// highlights that one when the sheet is reopened.
class SurahJumpButton extends StatefulWidget {
  const SurahJumpButton({
    super.key,
    required this.isMalayalam,
    required this.surahList,
    required this.currentSurahNumber,
    required this.arabicBlockList,
    required this.currentAyahNumber,
    required this.onAyahSelected,
  });

  final bool isMalayalam;
  final List<SurahModel> surahList;
  final int currentSurahNumber;
  final List<ArabicBlockModel> arabicBlockList;
  final int currentAyahNumber;
  final ValueChanged<int> onAyahSelected;

  @override
  State<SurahJumpButton> createState() => _SurahJumpButtonState();
}

class _SurahJumpButtonState extends State<SurahJumpButton> {
  /// The ayah the user most recently jumped to via this sheet.
  /// null = fall back to the scroll-derived [widget.currentAyahNumber].
  int? _lastJumpedAyah;

  @override
  void didUpdateWidget(SurahJumpButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset when the surah changes so the sheet starts at the first ayah.
    if (oldWidget.currentSurahNumber != widget.currentSurahNumber) {
      _lastJumpedAyah = null;
    }
  }

  int get _selectedAyah => _lastJumpedAyah ?? widget.currentAyahNumber;

  SurahModel? _findSurah() {
    for (final s in widget.surahList) {
      if (s.surahNumber == widget.currentSurahNumber) return s;
    }
    return null;
  }

  // Anchors the navigator sheet as a dropdown starting right below the
  // tapped chip, instead of a centered dialog.
  void _openSheet(BuildContext chipContext, {int? lockedTab}) {
    final renderBox = chipContext.findRenderObject() as RenderBox;
    final chipTopLeft = renderBox.localToGlobal(Offset.zero);
    final chipSize = renderBox.size;
    final screenSize = MediaQuery.sizeOf(context);

    const double margin = 12;
    // Ayah-only dropdown just lists short numbers — size it to how wide the
    // longest label ("N" or "N – M") in this surah actually renders,
    // instead of a fixed guess.
    final double ayahWidth = () {
      var maxChars = 1;
      for (final block in widget.arabicBlockList) {
        final start = block.verseFrom ?? 1;
        final end = block.verseTo ?? start;
        final label = start == end ? '$start' : '$start – $end';
        maxChars = label.length > maxChars ? label.length : maxChars;
      }
      const double horizontalContentPadding = 16 * 2; // ListTile padding
      const double charWidth = 9.0; // ~glyph width at fontSize 14
      const double extraSideMargin = 5 * 2; // +5px on each side
      return (maxChars * charWidth + horizontalContentPadding + 8 + extraSideMargin)
          .clamp(64.0, 200.0);
    }();
    final double baseWidth = lockedTab == 1 ? ayahWidth : 340.0;
    final double sheetWidth = (screenSize.width - margin * 2).clamp(
      0.0,
      baseWidth,
    );
    double left = chipTopLeft.dx;
    if (left + sheetWidth > screenSize.width - margin) {
      left = screenSize.width - sheetWidth - margin;
    }
    if (left < margin) left = margin;
    final double top = chipTopLeft.dy + chipSize.height + 8;
    final double availableHeight = (screenSize.height - top - margin).clamp(
      0.0,
      screenSize.height * 0.7,
    );
    // Ayah-only popup has no header/search/divider now — size it to the
    // actual row count (dense ListTile ≈ 34px incl. divider) instead of
    // always stretching toward the available space, only capping/scrolling
    // once a surah has enough ayahs to need it.
    const double ayahRowHeight = 34.0;
    final double ayahContentHeight =
        widget.arabicBlockList.length * ayahRowHeight;
    final double maxHeight = lockedTab == 1
        ? ayahContentHeight.clamp(ayahRowHeight, availableHeight)
        : availableHeight.clamp(200.0, screenSize.height * 0.7);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (sheetCtx, animation, secondaryAnimation) => Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: sheetWidth,
            child: Material(
              color: Theme.of(context).cardColor,
              elevation: 10,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: _SurahNavigatorSheet(
                  isMalayalam: widget.isMalayalam,
                  surahList: widget.surahList,
                  currentSurahNumber: widget.currentSurahNumber,
                  arabicBlockList: widget.arabicBlockList,
                  // Use the last explicitly-selected ayah, not the scroll-position one.
                  currentAyahNumber: _selectedAyah,
                  lockedTab: lockedTab,
                  onSurahSelected: (surahNumber) async {
                    Navigator.of(sheetCtx).pop();
                    // Reset jumped ayah for the new surah.
                    setState(() => _lastJumpedAyah = null);
                    await sheetCtx.read<SurahProvider>().selectSurahByNumber(
                      surahNumber,
                    );
                  },
                  onAyahSelected: (ayahStart) {
                    Navigator.of(sheetCtx).pop();
                    // Remember this as the last explicitly-selected ayah.
                    setState(() => _lastJumpedAyah = ayahStart);
                    widget.onAyahSelected(ayahStart);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      transitionBuilder: (transitionCtx, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final isDark = theme.brightness == Brightness.dark;
    final surah = _findSurah();

    final displayText = surah != null
        ? formatSurahListDisplayText(
            isMalayalam: widget.isMalayalam,
            surahName: surah.name,
            surahTranslation: surah.description,
            malayalamName: surah.malayalamName,
            surahNumber: surah.surahNumber,
          )
        : null;
    final surahLabel =
        displayText?.title ?? (widget.isMalayalam ? 'സൂറ' : 'Surah');

    final screenWidth = MediaQuery.sizeOf(context).width;
    // Narrow screens keep the tighter padding/font, but still carry the surah
    // name — the label ellipsizes within [surahChipMaxWidth] rather than being
    // dropped down to a bare number.
    final narrowChip = screenWidth < 640;

    const white = Colors.white;
    final fill = white.withValues(alpha: isDark ? 0.10 : 0.13);
    final border = white.withValues(alpha: 0.22);

    // The chip already shrinks to fit its label (Flexible + ellipsis); this
    // just scales the *cap* with screen width instead of a flat constant, so
    // it has more room on wide screens and stays tight on narrow ones.
    final double surahChipMaxWidth = narrowChip
        ? (screenWidth * 0.42).clamp(96.0, 180.0)
        : (screenWidth * 0.22).clamp(120.0, 220.0);

    Widget chip({
      required String label,
      required String semanticsLabel,
      required double maxWidth,
      required void Function(BuildContext chipContext) onTap,
    }) {
      return Builder(
        builder: (chipContext) => Semantics(
          button: true,
          label: semanticsLabel,
          child: GestureDetector(
            onTap: () => onTap(chipContext),
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: EdgeInsets.symmetric(
                horizontal: (narrowChip ? 5 : 8) * scale,
                vertical: (narrowChip ? 4 : 6) * scale,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(9 * scale),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: white,
                        fontSize: (narrowChip ? 10 : 10.5) * scale,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 3 * scale),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: white.withValues(alpha: 0.80),
                    size: (narrowChip ? 13 : 16) * scale,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Surah and ayah jump are two independent controls, not tabs of one
    // combined sheet — same on web and mobile.
    final surahChipLabel = '${widget.currentSurahNumber}. $surahLabel';
    final ayahChipLabel = widget.isMalayalam
        ? 'ആയത്ത് $_selectedAyah'
        : 'Ayah $_selectedAyah';

    return Padding(
      padding: EdgeInsets.all(4 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flexible so the pair degrades to an ellipsized surah label instead
          // of overflowing the app bar's title slot on narrow phones.
          Flexible(
            child: chip(
              label: surahChipLabel,
              semanticsLabel: 'Jump to surah',
              maxWidth: surahChipMaxWidth,
              onTap: (chipContext) => _openSheet(chipContext, lockedTab: 0),
            ),
          ),
          SizedBox(width: 6 * scale),
          chip(
            label: ayahChipLabel,
            semanticsLabel: 'Jump to ayah',
            maxWidth: narrowChip ? 90 : 110,
            onTap: (chipContext) => _openSheet(chipContext, lockedTab: 1),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SurahNavigatorSheet — modal sheet with Surah / Ayah tabs.
// ─────────────────────────────────────────────────────────────────────────────

class _SurahNavigatorSheet extends StatefulWidget {
  const _SurahNavigatorSheet({
    required this.isMalayalam,
    required this.surahList,
    required this.currentSurahNumber,
    required this.arabicBlockList,
    required this.currentAyahNumber,
    required this.onSurahSelected,
    required this.onAyahSelected,
    this.lockedTab,
  });

  final bool isMalayalam;
  final List<SurahModel> surahList;
  final int currentSurahNumber;
  final List<ArabicBlockModel> arabicBlockList;
  final int currentAyahNumber;
  final ValueChanged<int> onSurahSelected;
  final ValueChanged<int> onAyahSelected;
  // When set, hides the Surah/Ayah tab switcher and locks the sheet to a
  // single list (used on web where the two jump actions are separate).
  final int? lockedTab;

  @override
  State<_SurahNavigatorSheet> createState() => _SurahNavigatorSheetState();
}

class _SurahNavigatorSheetState extends State<_SurahNavigatorSheet> {
  late int _selectedTab = widget.lockedTab ?? 0; // 0 = Surah, 1 = Ayah
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _surahScrollCtrl = ScrollController();
  final ScrollController _ayahScrollCtrl = ScrollController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _surahScrollCtrl.dispose();
    _ayahScrollCtrl.dispose();
    super.dispose();
  }

  List<SurahModel> get _filteredSurahs {
    if (_searchQuery.isEmpty) return widget.surahList;
    final q = _searchQuery.toLowerCase();
    return widget.surahList.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.malayalamName.toLowerCase().contains(q) ||
          s.surahNumber.toString().contains(q) ||
          s.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final isMl = widget.isMalayalam;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final tabsLocked = widget.lockedTab != null;
    // The ayah-only popup (web) is small and self-explanatory — skip the
    // header, close button, and divider; the barrier tap already dismisses it.
    final showHeader = !(tabsLocked && _selectedTab == 1);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHeader) ...[
            // Tab header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
              child: Row(
                children: [
                  if (tabsLocked)
                    Text(
                      isMl ? 'സൂറത്ത്' : 'Surah',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else ...[
                    _TabButton(
                      label: isMl ? 'സൂറത്ത്' : 'Surah',
                      isSelected: _selectedTab == 0,
                      isMalayalam: isMl,
                      onTap: () {
                        if (_selectedTab != 0) {
                          setState(() => _selectedTab = 0);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '|',
                        style: TextStyle(color: cs.outline, fontSize: 14),
                      ),
                    ),
                    _TabButton(
                      label: isMl ? 'ആയത്ത്' : 'Ayah',
                      isSelected: _selectedTab == 1,
                      isMalayalam: isMl,
                      onTap: () {
                        if (_selectedTab != 1) {
                          setState(() => _selectedTab = 1);
                        }
                      },
                    ),
                  ],
                  const Spacer(),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      child: Icon(Icons.close, size: 16, color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          // Search field — Surah tab only; Ayah tab has no search.
          if (_selectedTab == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: AppTextTheme.localizedLabel(
                  isMalayalam: isMl,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: isMl ? 'സൂറത്ത് തിരയുക' : 'Search Surah',
                  hintStyle: AppTextTheme.localizedLabel(
                    isMalayalam: isMl,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          }),
                        ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
          // List body
          Flexible(
            child: _selectedTab == 0
                ? _buildSurahList(isDark, isMl, cs)
                : _buildAyahList(isDark, isMl, cs),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(bool isDark, bool isMl, ColorScheme cs) {
    final surahs = _filteredSurahs;
    if (surahs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isMl ? 'ഒന്നും കണ്ടെത്തിയില്ല' : 'No results found',
            style: TextStyle(color: cs.outline, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _surahScrollCtrl,
      itemCount: surahs.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 58, endIndent: 16),
      itemBuilder: (_, i) {
        final surah = surahs[i];
        final isSelected = surah.surahNumber == widget.currentSurahNumber;
        final displayText = formatSurahListDisplayText(
          isMalayalam: isMl,
          surahName: surah.name,
          surahTranslation: surah.description,
          malayalamName: surah.malayalamName,
          surahNumber: surah.surahNumber,
        );
        final placeKind = resolveSurahPlaceKind(surah.place);
        final placeIcon = placeKind == SurahPlaceKind.makkah
            ? _kMakkahIcon
            : _kMadinahIcon;
        final activeColor = isDark ? Colors.white : AppTheme.appThemePrimary;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${surah.surahNumber}',
              style: TextStyle(
                color: isSelected
                    ? (isDark ? AppTheme.appThemePrimary : Colors.white)
                    : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            displayText.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextTheme.localizedLabel(
              isMalayalam: isMl,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : cs.onSurface,
            ),
          ),
          subtitle: displayText.subtitle.isNotEmpty
              ? Text(
                  displayText.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                )
              : null,
          trailing: SvgPicture.asset(
            placeIcon,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              isSelected
                  ? activeColor
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.appThemePrimary.withValues(alpha: 0.45)),
              BlendMode.srcIn,
            ),
          ),
          selected: isSelected,
          onTap: () => widget.onSurahSelected(surah.surahNumber),
        );
      },
    );
  }

  Widget _buildAyahList(bool isDark, bool isMl, ColorScheme cs) {
    final blocks = widget.arabicBlockList;
    if (blocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isMl ? 'ആയത്തുകൾ ലഭ്യമല്ല' : 'No ayahs available',
            style: TextStyle(color: cs.outline, fontSize: 14),
          ),
        ),
      );
    }

    final activeColor = isDark ? Colors.white : AppTheme.appThemePrimary;

    return ListView.separated(
      controller: _ayahScrollCtrl,
      shrinkWrap: true,
      itemCount: blocks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final block = blocks[index];
        final start = block.verseFrom ?? index + 1;
        final end = block.verseTo ?? index + 1;
        final isSelected =
            start == widget.currentAyahNumber ||
            (widget.currentAyahNumber >= start &&
                widget.currentAyahNumber <= end);
        // Numbers only — the "Ayah" tab header already says what this list is.
        final label = start == end ? '$start' : '$start – $end';

        return ListTile(
          dense: true,
          visualDensity: const VisualDensity(vertical: -4),
          minVerticalPadding: 0,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          title: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextTheme.localizedLabel(
              isMalayalam: isMl,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : cs.onSurface,
            ),
          ),
          selected: isSelected,
          onTap: () => widget.onAyahSelected(start),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TabButton — pill tab used inside the navigator sheet header.
// ─────────────────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.isMalayalam,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isMalayalam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.appThemePrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextTheme.localizedLabel(
            isMalayalam: isMalayalam,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
