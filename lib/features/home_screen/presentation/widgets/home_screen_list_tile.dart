import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/utils/surah_place_localizer.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/star_number.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

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
    final isMl = context.watch<LanguageProvider>().isMalayalam;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode
        ? Colors.white
        : AppTheme.appThemePrimary;
    final subColor = isDarkMode ? Colors.white54 : Colors.grey[600]!;
    final lastSurahTabSelection =
        context.watch<LastReadProvider>().lastSurahTabSelection;
    final dividerColor = DividerTheme.of(context).color;
    final scale = ResponsiveHelper.scaleFactor(context);
    final placeColumnWidth = isMl ? 126 * scale : 96 * scale;
    final displayText = formatSurahListDisplayText(
      isMalayalam: isMl,
      surahName: surah.name,
      surahTranslation: surah.description,
      malayalamName: surah.malayalamName,
      surahNumber: surah.surahNumber,
    );
    final displayName = displayText.title;
    final description = displayText.subtitle;
    final placeName = localizeSurahPlace(surah.place, isMalayalam: isMl);
    final ayahLabel = formatAyahCountLabel(
      surah.ayathCount,
      isMalayalam: isMl,
    );
    final semanticsParts = [
      'Surah $displayName',
      if (description.isNotEmpty) description,
      'number ${surah.surahNumber}',
      '${surah.ayathCount} ayahs',
      if (placeName.isNotEmpty) placeName,
    ];

    return Semantics(
      button: true,
      label: semanticsParts.join(', '),
      hint: 'Double tap to open',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  StarNumber(
                    number: surah.surahNumber,
                    outlineOnly: true,
                    isHighlighted:
                        lastSurahTabSelection == surah.surahNumber,
                    size: 42,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextTheme.localizedLabel(
                            isMalayalam: isMl,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14 * scale,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextTheme.localizedBody(
                              isMalayalam: isMl,
                              fontSize: 11 * scale,
                              color: subColor,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  SizedBox(
                    width: placeColumnWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              placeName,
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.right,
                              style: AppTextTheme.localizedLabel(
                                isMalayalam: isMl,
                                color: subColor,
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ayahLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTextTheme.localizedLabel(
                            isMalayalam: isMl,
                            fontSize: 10.5 * scale,
                            color: subColor,
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
              const SizedBox(height: 6),
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
  }
}
