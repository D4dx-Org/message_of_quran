import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/features/favorites/provider/favorite_surah_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

/// Dashboard section listing the reader's favourited surahs. Renders nothing
/// once there are none, so it never reserves empty space on a fresh install.
class FavoriteSurahsSection extends StatelessWidget {
  const FavoriteSurahsSection({super.key, required this.onSurahTap});

  final void Function(int surahNumber) onSurahTap;

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final surahList = context.watch<SurahProvider>().surahList;
    final favoriteProvider = context.watch<FavoriteSurahProvider>();
    final favoriteNumbers = favoriteProvider.favoriteSurahNumbers;

    if (favoriteNumbers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            isMalayalam ? 'പ്രിയപ്പെട്ടവ' : 'Favourites',
            style: AppTextTheme.localizedTitle(
              isMalayalam: isMalayalam,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.appThemePrimary,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: favoriteNumbers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final surahNumber = favoriteNumbers[index];
              final surah = surahList
                  .where((s) => s.surahNumber == surahNumber)
                  .firstOrNull;
              final label = surah == null
                  ? 'Surah $surahNumber'
                  : formatSurahListDisplayText(
                      isMalayalam: isMalayalam,
                      surahName: surah.name,
                      surahTranslation: surah.description,
                      malayalamName: surah.malayalamName,
                      surahNumber: surah.surahNumber,
                    ).title;

              return GestureDetector(
                onTap: () => onSurahTap(surahNumber),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.appThemeRawChips,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: AppTextTheme.localizedLabel(
                          isMalayalam: isMalayalam,
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
