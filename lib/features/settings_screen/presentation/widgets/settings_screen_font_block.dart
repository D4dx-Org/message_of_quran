import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_selector_dropdown.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';

// Every font in the list, so the last one — QuranTaha — is not left
// below the fold with nothing to hint it exists.
const int _fontVisibleItemCount = 5;

class SettingsScreenFontBlock extends StatelessWidget {
  const SettingsScreenFontBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = appBarAccentColor(context);
    final controller = context.read<FontSizeChangerProvider>();

    return SettingsScreenCard(
      child: Column(
        children: [
          Consumer<FontSizeChangerProvider>(
            builder: (context, value, _) => SettingsScreenSelectorDropdown<String>(
              title: "Qur'an Font",
              icon: Icons.font_download,
              value: value.fontType,
              showFullSelectedValue: true,
              showFullPopupLabels: true,
              items: FontSizeChangerProvider.availableFonts,
              labelBuilder: (font) =>
                  FontSizeChangerProvider.fontDisplayNames[font] ?? font,
              visibleItemCount: _fontVisibleItemCount,
              onChanged: (font) {
                if (font != null) {
                  value.setFont(font);
                }
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SettingsScreenListTile(
            title: "Qur'an Font Size",
            icon: Icons.format_size_outlined,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => controller.decrement(true),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
                Consumer<FontSizeChangerProvider>(
                  builder: (context, value, child) {
                    return SizedBox(
                      width: 28,
                      child: Text(
                        '${value.quranFontSize}',
                        textAlign: TextAlign.center,
                        style: AppTextTheme.surahTitle.copyWith(
                          color: accentColor,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () => controller.increment(true),
                  icon: const Icon(Icons.add_circle_outline),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SettingsScreenListTile(
            title: 'Translation Font Size',
            icon: Icons.translate,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => controller.decrement(false),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
                Consumer<FontSizeChangerProvider>(
                  builder: (context, value, child) {
                    return SizedBox(
                      width: 28,
                      child: Text(
                        '${value.quranTransaltionFontSize}',
                        textAlign: TextAlign.center,
                        style: AppTextTheme.surahTitle.copyWith(
                          color: accentColor,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () => controller.increment(false),
                  icon: const Icon(Icons.add_circle_outline),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SettingsScreenListTile(
            title: 'Interpretation Font Size',
            icon: Icons.menu_book_outlined,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => controller.decrementInterpretation(),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
                Consumer<FontSizeChangerProvider>(
                  builder: (context, value, child) {
                    return SizedBox(
                      width: 28,
                      child: Text(
                        '${value.interpretationFontSize}',
                        textAlign: TextAlign.center,
                        style: AppTextTheme.surahTitle.copyWith(
                          color: accentColor,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () => controller.incrementInterpretation(),
                  icon: const Icon(Icons.add_circle_outline),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}