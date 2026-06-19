import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/platform_helper.dart';
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

/// Shows the settings as a centered, scrollable dialog overlay.
/// Use this everywhere instead of pushing [SettingsScreen] as a new route.
Future<void> showSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    final isMl = context.watch<LanguageProvider>().isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? theme.cardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant);
    final primaryColor = isDark ? Colors.white : AppTheme.appThemePrimary;
    final size = MediaQuery.sizeOf(context);
    const double maxDialogWidth = 620;
    final double hInset = size.width < 640
        ? 12.0
        : ((size.width - maxDialogWidth) / 2).clamp(24.0, double.infinity);
    final double maxHeight = (size.height * 0.88).clamp(300.0, 800.0);
    final showGeneralSection =
        SettingsScreen.shouldShowGeneralSection(isWeb: PlatformHelper.isWeb);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: hInset, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxDialogWidth,
            maxHeight: maxHeight,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isMl ? 'സെറ്റിംഗ്സ്' : 'Settings',
                          style: AppTextTheme.localizedTitle(
                            isMalayalam: isMl,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? theme.colorScheme.onSurface
                                : AppTheme.appThemePrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Scrollable settings content
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const _SectionLabel('Theme & Language'),
                      const SizedBox(height: 8),
                      const _ThemeLanguageCard(),
                      const SizedBox(height: 24),
                      const _SectionLabel('Font'),
                      const SizedBox(height: 8),
                      const SettingsScreenFontBlock(),
                      if (!PlatformHelper.isWeb) ...[
                        const SizedBox(height: 24),
                        const _SectionLabel('Layout'),
                        const SizedBox(height: 8),
                        const SettingsScreenLayoutBlock(),
                      ],
                      const SizedBox(height: 24),
                      const _SectionLabel('Tajweed'),
                      const SizedBox(height: 8),
                      const SettingsScreenTajweedBlock(),
                      const SizedBox(height: 24),
                      const _SectionLabel('Audio'),
                      const SizedBox(height: 8),
                      const SettingsScreenAudioBlock(),
                      if (showGeneralSection) ...[
                        const SizedBox(height: 24),
                        const _SectionLabel('General'),
                        const SizedBox(height: 8),
                        const SettingsScreenAppBlock(),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.showStandaloneBackAppBar = false,
  });

  final bool showStandaloneBackAppBar;

  bool _useDesktopWebLayout(BuildContext context) {
    return PlatformHelper.isWeb;
  }

  PreferredSizeWidget? _buildStandaloneAppBar(BuildContext context) {
    if (!showStandaloneBackAppBar) return null;

    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final scale = ResponsiveHelper.scaleFactor(context);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.appThemePrimary,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        isMalayalam ? 'സെറ്റിംഗ്സ്' : 'Settings',
        style: AppTextTheme.localizedTitle(
          isMalayalam: isMalayalam,
          fontSize: 18 * scale,
          fontWeight: FontWeight.w600,
          color: appBarTitleMatchedAccentColor(context),
        ),
      ),
    );
  }

  static bool shouldShowGeneralSection({required bool isWeb}) {
    return !isWeb;
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
    final showGeneralSection = shouldShowGeneralSection(
      isWeb: PlatformHelper.isWeb,
    );

    if (!useTwoColumns) {
      return ListView(
        padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 24),
        children: [
          const _SectionLabel('Theme & Language'),
          const SizedBox(height: 8),
          const _ThemeLanguageCard(),
          const SizedBox(height: 24),
          const _SectionLabel('Font'),
          const SizedBox(height: 8),
          const SettingsScreenFontBlock(),
          const SizedBox(height: 24),
          const _SectionLabel('Tajweed'),
          const SizedBox(height: 8),
          const SettingsScreenTajweedBlock(),
          const SizedBox(height: 24),
          const _SectionLabel('Audio'),
          const SizedBox(height: 8),
          const SettingsScreenAudioBlock(),
          if (showGeneralSection) ...[
            const SizedBox(height: 24),
            const _SectionLabel('General'),
            const SizedBox(height: 8),
            const SettingsScreenAppBlock(),
          ],
          const SizedBox(height: 24),
          const D4dxBrandingFooter(),
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
                  if (showGeneralSection) ...[
                    const SizedBox(height: 24),
                    _buildSectionGroup(
                      context,
                      label: 'General',
                      child: const SettingsScreenAppBlock(),
                    ),
                  ],
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
    final showGeneralSection = shouldShowGeneralSection(
      isWeb: PlatformHelper.isWeb,
    );

    return BaseScreenLayout(
      appBar: _buildStandaloneAppBar(context),
      contentCardBoxShadows: const [],
      child: useDesktopWebLayout
          ? _buildDesktopBody(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                const _SectionLabel('Theme & Language'),
                const SizedBox(height: 8),
                const _ThemeLanguageCard(),
                const SizedBox(height: 24),
                const _SectionLabel('Font'),
                const SizedBox(height: 8),
                const SettingsScreenFontBlock(),
                const SizedBox(height: 24),
                const _SectionLabel('Layout'),
                const SizedBox(height: 8),
                const SettingsScreenLayoutBlock(),
                const SizedBox(height: 24),
                const _SectionLabel('Tajweed'),
                const SizedBox(height: 8),
                const SettingsScreenTajweedBlock(),
                const SizedBox(height: 24),
                const _SectionLabel('Audio'),
                const SizedBox(height: 8),
                const SettingsScreenAudioBlock(),
                if (showGeneralSection) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel('General'),
                  const SizedBox(height: 8),
                  const SettingsScreenAppBlock(),
                ],
                const D4dxBrandingFooter(),
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
