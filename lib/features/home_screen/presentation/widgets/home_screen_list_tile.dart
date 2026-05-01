import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/star_number.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

bool _isMeccan(String place) =>
    place.contains('مكية') || place.toLowerCase().contains('mecca');

class HomeScreenListTile extends StatelessWidget {
  const HomeScreenListTile({super.key, required this.index, this.onTap});
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SurahProvider>(context);
    if (index < 0 || index >= controller.surahList.length) {
      return const SizedBox.shrink();
    }
    final surah = controller.surahList[index];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color.fromRGBO(124, 58, 40, 1);
    final subColor = isDarkMode ? Colors.white54 : Colors.grey[600]!;
    final lastReadSurah = context.watch<LastReadProvider>().surahNumber;

    final placeName = _isMeccan(surah.place) ? 'MEKKAH' : 'MADINAH';
    final placeType = _isMeccan(surah.place) ? 'Meccan' : 'Medinan';

    return Semantics(
      button: true,
      label: 'Surah ${surah.name}, number ${surah.surahNumber}, ${surah.ayathCount} ayahs, $placeType',
      hint: 'Double tap to open',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              StarNumber(
                number: surah.surahNumber,
                outlineOnly: true,
                isHighlighted: lastReadSurah == surah.surahNumber,
                size: 42,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.name,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$placeName  •  ${surah.ayathCount} AYAT',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: subColor,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                surah.arabicName,
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.87)
                      : const Color.fromRGBO(124, 58, 40, 1),
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
