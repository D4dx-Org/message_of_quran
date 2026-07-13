import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/services/database/database_ready_notifier.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/widgets/link_hover/hover_link.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/star_number.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

import 'home_list_row_text_styles.dart';

class JuzColumn extends StatelessWidget {
  const JuzColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final dbStatus = context.watch<DatabaseReadyNotifier>().status;
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

        if (provider.juzList.isEmpty &&
            (provider.isLoading || dbStatus == DbInitStatus.loading)) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.appIconTheme),
          );
        }

        if (provider.juzList.isEmpty && dbStatus == DbInitStatus.failed) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isMalayalam ? 'ജുസ്അ് ലഭ്യമല്ല' : 'Could not load Juz.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      context.read<DatabaseReadyNotifier>().retry(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.juzList.isEmpty) {
          return Center(
            child: Text(
              isMalayalam ? 'ജുസ്അ് ലഭ്യമല്ല' : 'No Juz available',
              style: AppTextTheme.localizedBody(
                isMalayalam: isMalayalam,
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : AppTheme.appThemePrimary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(hPad, homeListTopPadding, hPad, 0),
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

            final tile = Semantics(
              button: available,
              label: semanticsParts.join(', '),
              hint: available ? 'Double tap to open' : 'Not available',
              excludeSemantics: true,
              child: InkWell(
                onTap: available
                    ? () async {
                        await context.push(
                          '/surah/${juz.surahNumber}?scrollToAyahId=${juz.ayahNumber}',
                        );
                        if (!context.mounted) return;
                        unawaited(provider.selectJuz(juz.number));
                      }
                    : null,
                child: Padding(
                  padding: homeListRowPadding,
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
                            size: homeListBadgeSize,
                          ),
                          const SizedBox(width: homeListLeadingGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: homeListPrimaryTextStyle(
                                    isMalayalam: isMalayalam,
                                    color: primaryColor,
                                    scale: scale,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: homeListSubtitleTextStyle(
                                      isMalayalam: isMalayalam,
                                      color: secondaryColor,
                                      scale: scale,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: homeListTrailingGap),
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
                                  style: homeListAyahMetaTextStyle(
                                    isMalayalam: isMalayalam,
                                    color: secondaryColor,
                                    scale: scale,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: homeListEndGap),
                        ],
                      ),
                      const SizedBox(height: homeListRowBottomGap),
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

            return available
                ? HoverLink(
                    url:
                        '/surah/${juz.surahNumber}?scrollToAyahId=${juz.ayahNumber}',
                    child: tile,
                  )
                : tile;
          },
        );
      },
    );
  }
}
