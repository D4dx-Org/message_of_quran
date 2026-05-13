import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class SurahChipRow extends StatelessWidget {
  const SurahChipRow({super.key});

  static const List<({String labelEn, String labelMl, int surahNumber, int? ayahId})> _chips = [
    (labelEn: 'Ayatul Kursi', labelMl: 'ആയത്തുൽ കുർസി', surahNumber: 2, ayahId: 255),
    (labelEn: 'Yaseen', labelMl: '', surahNumber: 36, ayahId: null),
    (labelEn: 'Al Mulk', labelMl: '', surahNumber: 67, ayahId: null),
    (labelEn: 'Ar Rahman', labelMl: '', surahNumber: 55, ayahId: null),
    (labelEn: "Al Waqi'ah", labelMl: '', surahNumber: 56, ayahId: null),
    (labelEn: 'Al Kahf', labelMl: '', surahNumber: 18, ayahId: null),
  ];

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final surahList = context.watch<SurahProvider>().surahList;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = _chips[index];

          // Resolve label based on language
          String label;
          if (isMalayalam && chip.labelMl.isNotEmpty) {
            label = chip.labelMl;
          } else if (isMalayalam && surahList.isNotEmpty) {
            final surah = surahList.where((s) => s.surahNumber == chip.surahNumber).firstOrNull;
            label = (surah != null && surah.malayalamName.isNotEmpty)
                ? surah.malayalamName
                : chip.labelEn;
          } else {
            label = chip.labelEn;
          }

          return GestureDetector(
            onTap: () async {
              final surahProv = context.read<SurahProvider>();
              await surahProv.selectSurahByNumber(chip.surahNumber);
              if (!context.mounted) return;
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
                color: const Color.fromRGBO(124, 58, 40, 1),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: GoogleFonts.poppins(
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
