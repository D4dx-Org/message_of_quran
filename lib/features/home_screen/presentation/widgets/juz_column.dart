import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/star_number.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class JuzColumn extends StatelessWidget {
  const JuzColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<JuzHizbProvider, SurahProvider>(
      builder: (context, provider, surahProvider, _) {
        final hPad = ResponsiveHelper.horizontalPadding(context);
        final scale = ResponsiveHelper.scaleFactor(context);
        final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDarkMode
            ? Colors.white
          : AppTheme.appThemePrimary;
        final subColor = isDarkMode ? Colors.white54 : Colors.grey[600]!;
        final dividerColor = DividerTheme.of(context).color;

        if (provider.isLoading && provider.juzList.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.appIconTheme),
          );
        }

        if (provider.juzList.isEmpty) {
          return Center(
            child: Text(isMalayalam ? 'ജുസ് ലഭ്യമല്ല' : 'No Juz available'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
          itemCount: provider.juzList.length,
          itemBuilder: (context, index) {
            final juz = provider.juzList[index];
            final surahIndex = surahProvider.surahList.indexWhere(
              (s) => s.surahNumber == juz.surahNumber,
            );
            final available = surahIndex >= 0;
            final targetSurah = available
                ? surahProvider.surahList[surahIndex]
                : null;
            final primaryColor = available
                ? textColor
                : Colors.grey.withValues(alpha: 0.6);
            final secondaryColor = available
                ? subColor
                : Colors.grey.withValues(alpha: 0.5);
            final displayText = targetSurah == null
                ? SurahListDisplayText(
                    title: isMalayalam
                        ? 'സൂറത്ത് ${juz.surahNumber}'
                        : 'Surah ${juz.surahNumber}',
                    subtitle: '',
                  )
                : formatSurahListDisplayText(
                    isMalayalam: isMalayalam,
                    surahName: targetSurah.name,
                    surahTranslation: targetSurah.description,
                    malayalamName: targetSurah.malayalamName,
                    surahNumber: targetSurah.surahNumber,
                  );
            final title = displayText.title;
            final subtitle = displayText.subtitle;
            final startAyahLabel = formatAyahReferenceLabel(
              juz.ayahNumber,
              isMalayalam: isMalayalam,
            );
            final semanticsParts = [
              title,
              if (subtitle.isNotEmpty) subtitle,
              startAyahLabel,
            ];

            return Semantics(
              button: available,
              label: semanticsParts.join(', '),
              hint: available ? 'Double tap to open' : 'Not available',
              excludeSemantics: true,
              child: InkWell(
                onTap: available
                    ? () {
                        unawaited(provider.selectJuz(juz.number));
                        surahProvider.assignIndex(surahIndex);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SurahScreen(scrollToAyahId: juz.ayahNumber),
                          ),
                        );
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          StarNumber(
                            number: juz.number,
                            outlineOnly: true,
                            isHighlighted:
                                provider.selectedJuzNumber == juz.number,
                            size: 42,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12 * scale,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11 * scale,
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          SizedBox(
                            width: 96 * scale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  startAyahLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.poppins(
                                    color: secondaryColor,
                                    fontSize: 10.5 * scale,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 56,
                        endIndent: 8,
                        color: dividerColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
