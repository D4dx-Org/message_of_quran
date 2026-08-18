import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/features/favorites/provider/favorite_surah_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

/// Standalone screen, reached from the drawer, listing every surah the
/// reader has favourited. Tapping a row opens that surah; the heart icon
/// unfavourites it in place.
class FavoriteSurahsScreen extends StatelessWidget {
  const FavoriteSurahsScreen({super.key});

  void _openSurah(BuildContext context, int surahNumber) {
    context.push('/surah/$surahNumber');
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;

    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: isMalayalam ? 'പ്രിയപ്പെട്ടവ' : 'Favourites',
        showLanguageButton: false,
      ),
      drawer: const CommonDrawer(),
      child: Consumer2<FavoriteSurahProvider, SurahProvider>(
        builder: (context, favoriteProvider, surahProvider, _) {
          final favoriteNumbers = favoriteProvider.favoriteSurahNumbers;

          if (favoriteNumbers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 48,
                      color: AppTheme.appIconTheme.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isMalayalam
                          ? 'ഇതുവരെ പ്രിയപ്പെട്ടവ ചേർത്തിട്ടില്ല'
                          : 'No favourites yet',
                      style: AppTextTheme.localizedBody(
                        isMalayalam: isMalayalam,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isMalayalam
                          ? 'ഒരു സൂറത്ത് വായിക്കുമ്പോൾ ഹൃദയം ഐക്കൺ അമർത്തി പ്രിയപ്പെട്ടതാക്കുക.'
                          : 'Tap the heart icon while reading a surah to add it here.',
                      textAlign: TextAlign.center,
                      style: AppTextTheme.localizedBody(
                        isMalayalam: isMalayalam,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: favoriteNumbers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final surahNumber = favoriteNumbers[index];
              final surah = surahProvider.surahList
                  .where((s) => s.surahNumber == surahNumber)
                  .firstOrNull;
              final title = surah == null
                  ? 'Surah $surahNumber'
                  : formatSurahListDisplayText(
                      isMalayalam: isMalayalam,
                      surahName: surah.name,
                      surahTranslation: surah.description,
                      malayalamName: surah.malayalamName,
                      surahNumber: surah.surahNumber,
                    ).title;
              final subtitle = surah?.description ?? '';

              return Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  onTap: () => _openSurah(context, surahNumber),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.appThemePrimary,
                    child: Text(
                      '$surahNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(
                    title,
                    style: AppTextTheme.localizedLabel(
                      isMalayalam: isMalayalam,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: subtitle.isEmpty
                      ? null
                      : Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: IconButton(
                    tooltip: isMalayalam
                        ? 'നീക്കം ചെയ്യുക'
                        : 'Remove from Favourites',
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => favoriteProvider.toggle(surahNumber),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
