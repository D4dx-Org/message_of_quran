import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/d4dx_branding_footer.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_app_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_audio_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_font_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_layout_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_tajweed_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  bool _useDesktopWebLayout(BuildContext context) {
    return kIsWeb;
  }

  Widget _buildSectionGroup(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDesktopBody(BuildContext context) {
    final hPad = ResponsiveHelper.horizontalPadding(context);
    final useTwoColumns = MediaQuery.sizeOf(context).width >= 980;

    if (!useTwoColumns) {
      return ListView(
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
        children: const [
          _SectionLabel('Theme & Language'),
          SizedBox(height: 8),
          _ThemeLanguageCard(),
          SizedBox(height: 24),
          _SectionLabel('Font'),
          SizedBox(height: 8),
          SettingsScreenFontBlock(),
          SizedBox(height: 24),
          _SectionLabel('Layout'),
          SizedBox(height: 8),
          SettingsScreenLayoutBlock(),
          SizedBox(height: 24),
          _SectionLabel('Tajweed'),
          SizedBox(height: 8),
          SettingsScreenTajweedBlock(),
          SizedBox(height: 24),
          _SectionLabel('Audio'),
          SizedBox(height: 8),
          SettingsScreenAudioBlock(),
          SizedBox(height: 24),
          _SectionLabel('General'),
          SizedBox(height: 8),
          SettingsScreenAppBlock(),
          SizedBox(height: 24),
          D4dxBrandingFooter(),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionGroup(
                    context,
                    label: 'Theme & Language',
                    child: const _ThemeLanguageCard(),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionGroup(
                    context,
                    label: 'Font',
                    child: const SettingsScreenFontBlock(),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionGroup(
                    context,
                    label: 'Layout',
                    child: const SettingsScreenLayoutBlock(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionGroup(
                    context,
                    label: 'Tajweed',
                    child: const SettingsScreenTajweedBlock(),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionGroup(
                    context,
                    label: 'Audio',
                    child: const SettingsScreenAudioBlock(),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionGroup(
                    context,
                    label: 'General',
                    child: const SettingsScreenAppBlock(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const D4dxBrandingFooter(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final useDesktopWebLayout = _useDesktopWebLayout(context);

    return BaseScreenLayout(
      contentCardBoxShadows: const [],
      child: useDesktopWebLayout
          ? _buildDesktopBody(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: const [
                _SectionLabel('Theme & Language'),
                SizedBox(height: 8),
                _ThemeLanguageCard(),
                SizedBox(height: 24),
                _SectionLabel('Font'),
                SizedBox(height: 8),
                SettingsScreenFontBlock(),
                SizedBox(height: 24),
                _SectionLabel('Layout'),
                SizedBox(height: 8),
                SettingsScreenLayoutBlock(),
                SizedBox(height: 24),
                _SectionLabel('Tajweed'),
                SizedBox(height: 8),
                SettingsScreenTajweedBlock(),
                SizedBox(height: 24),
                _SectionLabel('Audio'),
                SizedBox(height: 8),
                SettingsScreenAudioBlock(),
                SizedBox(height: 24),
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
    final usesMalayalamFont = RegExp(r'[\u0D00-\u0D7F]').hasMatch(label);

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
              style: AppTextTheme.localizedLabel(
                isMalayalam: usesMalayalamFont,
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
