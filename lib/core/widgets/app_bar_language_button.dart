import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

const Color _homeLanguageButtonAccent = Color(0xFFF2F2F7);

class AppBarLanguageButton extends StatefulWidget {
  const AppBarLanguageButton({super.key, this.showText = true, this.iconSize = 15});

  final bool showText;
  final double iconSize;

  @override
  State<AppBarLanguageButton> createState() => _AppBarLanguageButtonState();
}

class _AppBarLanguageButtonState extends State<AppBarLanguageButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, provider, _) {
        final selectedLanguage = provider.currentLanguage;
        final isMalayalam = selectedLanguage == LanguageProvider.malayalam;
        const buttonAccent = _homeLanguageButtonAccent;
        final iconOnly = !widget.showText;

        // Icon-only (mobile) mode: no border by default, hover box like nav items
        final hoverBgColor = buttonAccent.withValues(alpha: 0.14);
        final hoverBorderColor = buttonAccent.withValues(alpha: 0.24);

        final child = iconOnly
            ? MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isHovered ? hoverBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isHovered ? hoverBorderColor : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.language_rounded,
                        size: widget.iconSize,
                        color: buttonAccent,
                      ),
                      const SizedBox(height: 2),
                      // Match the 1.5px underline spacer used by nav items
                      const SizedBox(height: 1.5),
                    ],
                  ),
                ),
              )
            : Container(
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
                    const Icon(Icons.language_rounded, size: 15, color: buttonAccent),
                    const SizedBox(width: 4),
                    Text(
                      isMalayalam ? 'ML' : 'EN',
                      style: AppTextTheme.popinsDefault(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: buttonAccent,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: buttonAccent,
                    ),
                  ],
                ),
              );

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
            child: child,
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
                style: AppTextTheme.popinsDefault(
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
                style: AppTextTheme.localizedLabel(
                  isMalayalam: useMalayalamFont,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
