import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

const Color _homeLanguageButtonAccent = Color(0xFFF2F2F7);

class AppBarLanguageButton extends StatelessWidget {
  const AppBarLanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, provider, _) {
        final selectedLanguage = provider.currentLanguage;
        final isMalayalam = selectedLanguage == LanguageProvider.malayalam;
        const buttonAccent = _homeLanguageButtonAccent;

        return Semantics(
          button: true,
          label: isMalayalam ? 'ഭാഷ മാറ്റുക' : 'Change language',
          hint: isMalayalam
              ? 'ഇംഗ്ലീഷോ മലയാളമോ തിരഞ്ഞെടുക്കുക'
              : 'Choose English or Malayalam',
          child: PopupMenuButton<String>(
            tooltip: isMalayalam ? 'ഭാഷ മാറ്റുക' : 'Change language',
            initialValue: selectedLanguage,
            onSelected: (value) => _selectLanguage(context, value),
            position: PopupMenuPosition.under,
            offset: const Offset(0, 10),
            padding: EdgeInsets.zero,
            color: Theme.of(context).cardColor,
            surfaceTintColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemBuilder: (menuContext) => [
              _buildMenuItem(
                menuContext,
                value: LanguageProvider.english,
                code: 'EN',
                label: 'English',
                selected: selectedLanguage == LanguageProvider.english,
              ),
              _buildMenuItem(
                menuContext,
                value: LanguageProvider.malayalam,
                code: 'ML',
                label: 'മലയാളം',
                selected: selectedLanguage == LanguageProvider.malayalam,
                useMalayalamFont: true,
              ),
            ],
            child: Container(
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: buttonAccent.withValues(alpha: 0.10),
                border: Border.all(color: buttonAccent.withValues(alpha: 0.45)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language_rounded, size: 15, color: buttonAccent),
                  const SizedBox(width: 4),
                  Text(
                    isMalayalam ? 'ML' : 'EN',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: buttonAccent,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: buttonAccent,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static PopupMenuItem<String> _buildMenuItem(
    BuildContext context, {
    required String value,
    required String code,
    required String label,
    required bool selected,
    bool useMalayalamFont = false,
  }) {
    final accentColor = appBarAccentColor(context);
    final labelColor = selected
        ? accentColor
        : Theme.of(context).colorScheme.onSurface;

    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? appBarAccentFillColor(context, alpha: 0.18)
                    : appBarAccentFillColor(context, alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style:
                    (useMalayalamFont
                            ? GoogleFonts.notoSerifMalayalam()
                            : GoogleFonts.poppins())
                        .copyWith(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: labelColor,
                        ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 18, color: accentColor),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, String language) {
    final languageProvider = context.read<LanguageProvider>();
    if (languageProvider.currentLanguage == language) {
      return;
    }

    languageProvider.setLanguage(language);
    context.read<SurahProvider>().setMalayalam(
      language == LanguageProvider.malayalam,
    );
  }
}
