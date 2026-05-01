import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';

class SettingsScreenDarkModeBlock extends StatelessWidget {
  const SettingsScreenDarkModeBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenCard(
      child: SettingsScreenListTile(
        title: "Dark Theme",

        icon: Icons.dark_mode_outlined,
        trailing: Consumer<ThemeProvider>(
          builder: (context, provider, child) {
            return Switch.adaptive(
              value: provider.isDarkMode,
              activeThumbColor: AppTheme.appIconTheme,
              thumbIcon: WidgetStatePropertyAll(
                Icon(
                  provider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.white,
                ),
              ),
              onChanged: (value) {
                provider.setThemeMode(!provider.isDarkMode);
              },
            );
          },
        ),
      ),
    );
  }
}
