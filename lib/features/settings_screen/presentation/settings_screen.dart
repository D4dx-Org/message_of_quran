import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/d4dx_branding_footer.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_app_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_audio_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_layout_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_tajweed_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      contentCardBoxShadows: const [],
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: const [
          // ── Theme & Language ──────────────────────────────────
          _SectionLabel('Theme & Language'),
          SizedBox(height: 8),
          _ThemeLanguageCard(),
          SizedBox(height: 24),

          // ── Font Settings ────────────────────────────────────
          _SectionLabel('Font'),
          SizedBox(height: 8),
          _FontSettingsCard(),
          SizedBox(height: 24),

          // ── Layout ───────────────────────────────────────────
          _SectionLabel('Layout'),
          SizedBox(height: 8),
          SettingsScreenLayoutBlock(),
          SizedBox(height: 24),

          // ── Tajweed ──────────────────────────────────────────
          _SectionLabel('Tajweed'),
          SizedBox(height: 8),
          SettingsScreenTajweedBlock(),
          SizedBox(height: 24),

          // ── Audio ──────────────────────────────────────────
          _SectionLabel('Audio'),
          SizedBox(height: 8),
          SettingsScreenAudioBlock(),
          SizedBox(height: 24),

          // ── General ────────────────────────────────────────
          _SectionLabel('General'),
          SizedBox(height: 8),
          SettingsScreenAppBlock(),
          D4dxBrandingFooter(),
        ],
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.outline,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Theme & Language Card ───────────────────────────────────────────────────

class _ThemeLanguageCard extends StatelessWidget {
  const _ThemeLanguageCard();

  @override
  Widget build(BuildContext context) {
    final accentColor = appBarAccentColor(context);
    final accentTrackColor = appBarAccentFillColor(context, alpha: 0.35);

    return SettingsScreenCard(
      child: Column(
        children: [
          // Dark theme toggle
          SettingsScreenListTile(
            title: 'Dark Theme',
            icon: Icons.dark_mode_outlined,
            trailing: Consumer<ThemeProvider>(
              builder: (context, provider, child) {
                return Switch.adaptive(
                  value: provider.isDarkMode,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentTrackColor,
                  thumbIcon: WidgetStatePropertyAll(
                    Icon(
                      provider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: provider.isDarkMode
                          ? Theme.of(context).scaffoldBackgroundColor
                          : Colors.white,
                    ),
                  ),
                  onChanged: (value) {
                    provider.setThemeMode(!provider.isDarkMode);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Language selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.language, color: accentColor),
                    const SizedBox(width: 16),
                    Text(
                      'Language',
                      style: AppTextTheme.drawerStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
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
                            selected:
                                provider.currentLanguage ==
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
                            selected:
                                provider.currentLanguage ==
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
        ],
      ),
    );
  }
}

// ─── Font Settings Card ──────────────────────────────────────────────────────

class _FontSettingsCard extends StatelessWidget {
  const _FontSettingsCard();

  @override
  Widget build(BuildContext context) {
    final accentColor = appBarAccentColor(context);
    final controller = Provider.of<FontSizeChangerProvider>(context);

    return SettingsScreenCard(
      child: Column(
        children: [
          // Font picker
          Consumer<FontSizeChangerProvider>(
            builder: (context, value, _) => SettingsScreenListTile(
              title: "Qur'an Font",
              icon: Icons.font_download,
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value.fontType,
                  icon: Icon(Icons.arrow_drop_down, color: accentColor),
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
                          FontSizeChangerProvider.fontDisplayNames[font] ??
                              font,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
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
                                  ? accentColor
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check, size: 16, color: accentColor),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Qur'an font size
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
          // Translation font size
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
          // Interpretation font size
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

// ─── Language Chip ───────────────────────────────────────────────────────────

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
    final accentColor = appBarAccentColor(context);
    final accentFillColor = appBarAccentFillColor(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? accentFillColor : Colors.transparent,
          border: Border.all(
            color: selected ? accentColor : Colors.grey.shade400,
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
                color: selected ? accentColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
