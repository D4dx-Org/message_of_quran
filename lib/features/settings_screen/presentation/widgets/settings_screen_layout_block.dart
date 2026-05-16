import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

class SettingsScreenLayoutBlock extends StatelessWidget {
  const SettingsScreenLayoutBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = appBarAccentColor(context);
    final accentTrackColor = appBarAccentFillColor(context, alpha: 0.35);
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;

    return SettingsScreenCard(
      child: Column(
        children: [
          if (!isMalayalam) ...[
            Consumer<FontSizeChangerProvider>(
              builder: (context, value, _) => SettingsScreenListTile(
                title: 'Justify Translation',
                icon: Icons.format_align_justify,
                trailing: Switch(
                  value: value.translationJustify,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentTrackColor,
                  onChanged: value.setTranslationJustify,
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],
          Consumer<FontSizeChangerProvider>(
            builder: (context, value, _) => SettingsScreenListTile(
              title: 'Justify Interpretation',
              icon: Icons.notes,
              trailing: Switch(
                value: value.interpretationJustify,
                activeThumbColor: accentColor,
                activeTrackColor: accentTrackColor,
                onChanged: value.setInterpretationJustify,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Consumer<FontSizeChangerProvider>(
            builder: (context, value, _) => SettingsScreenListTile(
              title: 'Justify Quran Ayahs & Tajweed',
              icon: Icons.auto_stories_outlined,
              trailing: Switch(
                value: value.quranJustify,
                activeThumbColor: accentColor,
                activeTrackColor: accentTrackColor,
                onChanged: value.setQuranJustify,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
