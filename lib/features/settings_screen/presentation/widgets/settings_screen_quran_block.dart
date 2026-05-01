import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';

class SettingsScreenQuranBlock extends StatelessWidget {
  const SettingsScreenQuranBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FontSizeChangerProvider>(context);
    return SettingsScreenCard(
      child: Column(
        children: [
          Consumer<FontSizeChangerProvider>(
            builder: (context, value, _) => SettingsScreenListTile(
              title: "Qur'an Font",
              icon: Icons.font_download,
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value.fontType,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.appIconTheme,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  dropdownColor: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (val) {
                    if (val != null) value.setFont(val);
                  },
                  selectedItemBuilder: (context) {
                    return FontSizeChangerProvider.availableFonts.map((font) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          FontSizeChangerProvider.fontDisplayNames[font] ?? font,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.appIconTheme,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  items: FontSizeChangerProvider.availableFonts.map((font) {
                    final isSelected = value.fontType == font;
                    return DropdownMenuItem<String>(
                      value: font,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            FontSizeChangerProvider.fontDisplayNames[font] ??
                                font,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppTheme.appIconTheme
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: AppTheme.appIconTheme,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SettingsScreenListTile(
            title: "Qur'an Font Size",
            icon: Icons.format_size_outlined,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    controller.decrement(true);
                  },
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Consumer<FontSizeChangerProvider>(
                  builder: (context, value, child) {
                    return Text(
                      "${value.quranFontSize}",
                      style: AppTextTheme.surahTitle.copyWith(
                        color: AppTheme.appIconTheme,
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () {
                    controller.increment(true);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          SettingsScreenListTile(
            title: "Translation Font Size",
            icon: Icons.translate,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    controller.decrement(false);
                  },
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Consumer<FontSizeChangerProvider>(
                  builder: (context, value, child) {
                    return Text(
                      "${value.quranTransaltionFontSize}",
                      style: AppTextTheme.surahTitle.copyWith(
                        color: AppTheme.appIconTheme,
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () {
                    controller.increment(false);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          Consumer<FontSizeChangerProvider>(
            builder: (context, value, _) => SettingsScreenListTile(
              title: 'Justify Translation',
              icon: Icons.format_align_justify,
              trailing: Switch(
                value: value.translationJustify,
                activeThumbColor: AppTheme.appIconTheme,
                onChanged: value.setTranslationJustify,
              ),
            ),
          ),
          SettingsScreenListTile(
            title: "Interpretation Font Size",
            icon: Icons.menu_book_outlined,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    controller.decrementInterpretation();
                  },
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Consumer<FontSizeChangerProvider>(
                  builder: (context, value, child) {
                    return Text(
                      "${value.interpretationFontSize}",
                      style: AppTextTheme.surahTitle.copyWith(
                        color: AppTheme.appIconTheme,
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () {
                    controller.incrementInterpretation();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          Consumer<FontSizeChangerProvider>(
            builder: (context, value, _) => SettingsScreenListTile(
              title: 'Justify Interpretation',
              icon: Icons.notes,
              trailing: Switch(
                value: value.interpretationJustify,
                activeThumbColor: AppTheme.appIconTheme,
                onChanged: value.setInterpretationJustify,
              ),
            ),
          ),
          Consumer<FontSizeChangerProvider>(
            builder: (context, value, _) => SettingsScreenListTile(
              title: 'Justify Quran Ayahs & Tajweed',
              icon: Icons.auto_stories_outlined,
              trailing: Switch(
                value: value.quranJustify,
                activeThumbColor: AppTheme.appIconTheme,
                onChanged: value.setQuranJustify,
              ),
            ),
          ),
          Consumer<PlaySettingsProvider>(
            builder: (context, playSettings, _) => SettingsScreenListTile(
              title: 'Horizontal Scroll',
              icon: Icons.swap_horiz,
              trailing: Switch(
                value: playSettings.verticalScroll,
                activeThumbColor: AppTheme.appIconTheme,
                onChanged: (v) => playSettings.setVerticalScroll(v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
