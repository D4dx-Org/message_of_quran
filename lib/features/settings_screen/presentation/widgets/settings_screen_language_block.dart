import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class SettingsScreenLanguageBlock extends StatelessWidget {
  const SettingsScreenLanguageBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
            const    Icon(Icons.language, color: AppTheme.appIconTheme),
                const SizedBox(width: 12),
                Text(
                  'Language',
                  style: AppTextTheme.drawerStyle
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<LanguageProvider>(
              builder: (context, provider, child) {
                return Row(
                  children: [
                    Expanded(
                      child: _LanguageChip(
                        label: 'English',
                        selected: provider.currentLanguage ==
                            LanguageProvider.english,
                        onTap: () {
                          provider.setLanguage(LanguageProvider.english);
                          context.read<SurahProvider>().setMalayalam(false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LanguageChip(
                        label: 'മലയാ\u200dളം',
                        selected: provider.currentLanguage ==
                            LanguageProvider.malayalam,
                        onTap: () {
                          provider.setLanguage(LanguageProvider.malayalam);
                          context.read<SurahProvider>().setMalayalam(true);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.appIconTheme.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppTheme.appIconTheme : Colors.grey.shade400,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppTheme.appIconTheme : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
