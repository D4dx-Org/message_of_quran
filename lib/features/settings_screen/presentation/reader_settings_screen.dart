import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

class ReaderSettingsScreen extends StatelessWidget {
  const ReaderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;

    return SettingsScreen(
      appBar: AppBar(
        title: Text(
          isMalayalam ? 'സെറ്റിംഗ്സ്' : 'Settings',
          style: AppTextTheme.localizedTitle(
            isMalayalam: isMalayalam,
            color: AppTheme.appBarForegroundColor,
          ),
        ),
      ),
    );
  }
}