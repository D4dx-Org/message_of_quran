import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class SurahChipRow extends StatelessWidget {
  const SurahChipRow({super.key});

  static const List<({int surahNumber, int? ayahId})> chips = [
    (surahNumber: 2, ayahId: 255),
    (surahNumber: 36, ayahId: null),
    (surahNumber: 67, ayahId: null),
    (surahNumber: 55, ayahId: null),
    (surahNumber: 56, ayahId: null),
    (surahNumber: 18, ayahId: null),
  ];

  static String _chipLabel({
    required bool isMalayalam,
    required List<SurahModel> surahList,
    required int surahNumber,
    int? ayahId,
  }) {
    if (ayahId == 255) return formatAyatulKursiLabel(isMalayalam: isMalayalam);

    final surah = surahList
        .where((s) => s.surahNumber == surahNumber)
        .firstOrNull;
    if (surah == null) return 'Surah $surahNumber';

    return formatSurahListDisplayText(
      isMalayalam: isMalayalam,
      surahName: surah.name,
      surahTranslation: surah.description,
      malayalamName: surah.malayalamName,
      surahNumber: surah.surahNumber,
    ).title;
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final surahList = context.watch<SurahProvider>().surahList;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final label = _chipLabel(
            isMalayalam: isMalayalam,
            surahList: surahList,
            surahNumber: chip.surahNumber,
            ayahId: chip.ayahId,
          );

          return GestureDetector(
            onTap: () {
              // Open the surah EXACTLY like the other chips (Yaseen,
              // Al Mulk, etc.) — just assignIndex and push immediately.
              // SurahScreen loads its data and, when scrollToAyahId is
              // non-null (e.g. Ayatul Kursi = 255), automatically scrolls
              // to that ayah once the layout is ready. Avoiding any
              // pre-navigation `await` here removes the visible tap-lag
              // and the double-screen flash on the home screen.
              final surahProv = context.read<SurahProvider>();
              final idx = surahProv.surahList.indexWhere(
                (s) => s.surahNumber == chip.surahNumber,
              );
              if (idx < 0) return;
              surahProv.assignIndex(idx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahScreen(
                    scrollToAyahId: chip.ayahId,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.appThemeRawChips,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppTextTheme.localizedLabel(
                  isMalayalam: isMalayalam,
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
