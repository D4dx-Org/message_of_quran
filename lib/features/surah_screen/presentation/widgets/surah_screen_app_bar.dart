import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

bool _isMeccan(String place) =>
    place.contains('مكية') || place.toLowerCase().contains('mecca');

String _placeArabic(String place) => _isMeccan(place) ? 'مكية' : 'مدنية';

String _toArabicNumerals(int value) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
}

String _getPlaceIcon(String place) {
  return _isMeccan(place)
      ? 'assets/icons/revamp/makkah_icon.svg'
      : 'assets/icons/revamp/madeena_icon.svg';
}

/// Compact, attractive surah info strip with gradient, number badge, and nav arrows.
class SurahInfoStrip extends StatelessWidget {
  final String arabicName;
  final String place;
  final int ayahCount;
  final int surahNumber;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool showPrevious;
  final bool showNext;

  const SurahInfoStrip({
    super.key,
    required this.arabicName,
    required this.place,
    required this.ayahCount,
    required this.surahNumber,
    this.onPrevious,
    this.onNext,
    this.showPrevious = true,
    this.showNext = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.appThemePrimary, Color(0xFF7E3A24)],
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        arabicName,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            _getPlaceIcon(place),
                            width: 12,
                            height: 12,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF8789A3),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_placeArabic(place)}،  آياتها  ${_toArabicNumerals(ayahCount)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.3,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
              ],
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
              side: BorderSide(color: AppTheme.appIconTheme.withValues(alpha: 0.4)),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
          ),
          icon: Icon(icon),
        ),
      ),
    );
  }
}

/// Compact header shown on non-first pages in PageView mode.
/// Displays surah name, page indicator, and prev/next surah buttons.
class SurahCompactHeader extends StatelessWidget {
  final String arabicName;
  final String pageText;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool showPrevious;
  final bool showNext;

  const SurahCompactHeader({
    super.key,
    required this.arabicName,
    required this.pageText,
    this.onPrevious,
    this.onNext,
    this.showPrevious = true,
    this.showNext = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _compactNavBtn(Icons.arrow_back_ios_new, showPrevious, onPrevious),
          const SizedBox(width: 14),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                arabicName,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                pageText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          _compactNavBtn(Icons.arrow_forward_ios_rounded, showNext, onNext),
        ],
      ),
    );
  }

  Widget _compactNavBtn(IconData icon, bool visible, VoidCallback? onPressed) {
    return Visibility(
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      visible: visible,
      child: SizedBox(
        width: 24,
        height: 24,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: 12,
          color: Colors.white,
          style: IconButton.styleFrom(
            shape: CircleBorder(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
            ),
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
    return SliverToBoxAdapter(
      child: Consumer<SurahProvider>(
        builder: (context, sp, _) {
          if (sp.surahList.isEmpty || sp.index >= sp.surahList.length) {
            return const SizedBox.shrink();
          }
          final surah = sp.surahList[sp.index];
          return SurahInfoStrip(
            arabicName: surah.arabicName,
            place: surah.place,
            ayahCount: surah.ayathCount,
            surahNumber: sp.index + 1,
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
