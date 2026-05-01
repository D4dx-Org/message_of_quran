import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class SurahChipRow extends StatelessWidget {
  const SurahChipRow({super.key});

  static const List<({String label, int surahNumber, int? ayahId})> _chips = [
    (label: 'Ayatul Kursi', surahNumber: 2, ayahId: 255),
    (label: 'Yaseen', surahNumber: 36, ayahId: null),
    (label: 'Al Mulk', surahNumber: 67, ayahId: null),
    (label: 'Ar Rahman', surahNumber: 55, ayahId: null),
    (label: "Al Waqi'ah", surahNumber: 56, ayahId: null),
    (label: 'Al Kahf', surahNumber: 18, ayahId: null),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = _chips[index];
          return GestureDetector(
            onTap: () async {
              final surahProv = context.read<SurahProvider>();
              await surahProv.selectSurahByNumber(chip.surahNumber);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurahScreen(
                      scrollToAyahId: chip.ayahId,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(124, 58, 40, 1),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                chip.label,
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
