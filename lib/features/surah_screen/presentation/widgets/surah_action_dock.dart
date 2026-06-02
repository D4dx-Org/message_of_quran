import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';

const double surahActionDockHeight = 56;
const double surahActionDockDefaultBottomGap = 16;
const double surahActionDockMinimumBottomGap = 6;
const double surahActionDockSidePadding = 24;
const double surahActionDockMaxWidth = 296;

double resolveSurahActionDockBottomPadding({required double rootBottomInset}) {
  return math.max(
    surahActionDockMinimumBottomGap,
    surahActionDockDefaultBottomGap - rootBottomInset,
  );
}

double resolveSurahActionDockClearance({required double rootBottomInset}) {
  return resolveSurahActionDockBottomPadding(
        rootBottomInset: rootBottomInset,
      ) +
      surahActionDockHeight +
      12;
}

class SurahActionDock extends StatelessWidget {
  const SurahActionDock({
    super.key,
    required this.visible,
    required this.bottomPadding,
    this.useAssetIcons = true,
    required this.onHomePressed,
    required this.onJumpToAyahPressed,
    required this.onPlayFromBeginningPressed,
    required this.onSettingsPressed,
  });

  final bool visible;
  final double bottomPadding;
  final bool useAssetIcons;
  final VoidCallback onHomePressed;
  final VoidCallback onJumpToAyahPressed;
  final VoidCallback onPlayFromBeginningPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final dockBg = isDarkMode
        ? const Color(0xff0c2d52)
        : const Color.fromRGBO(255, 248, 235, 1);
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : AppTheme.appIconTheme.withValues(alpha: 0.16);
    final dividerColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.10)
        : theme.colorScheme.outlineVariant;

    return Align(
      alignment: Alignment.bottomCenter,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: visible ? Offset.zero : const Offset(0, 0.35),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            opacity: visible ? 1 : 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                surahActionDockSidePadding,
                0,
                surahActionDockSidePadding,
                bottomPadding,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: surahActionDockMaxWidth),
                child: GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    container: true,
                    label: 'Surah quick actions',
                    child: Material(
                      key: const Key('surahActionDockMaterial'),
                      color: dockBg,
                      elevation: 10,
                      shadowColor: Colors.black.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SurahActionDockButton(
                              tooltip: 'Home',
                              assetPath: useAssetIcons
                                  ? 'assets/icons/home-img.png'
                                  : null,
                              icon: useAssetIcons ? null : Icons.home_outlined,
                              onPressed: onHomePressed,
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: dividerColor,
                            ),
                            _SurahActionDockButton(
                              tooltip: 'Jump to Ayah',
                              icon: Icons.format_list_numbered,
                              onPressed: onJumpToAyahPressed,
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: dividerColor,
                            ),
                            _SurahActionDockButton(
                              tooltip: 'Play from beginning',
                              icon: Icons.play_circle_outline_rounded,
                              onPressed: onPlayFromBeginningPressed,
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: dividerColor,
                            ),
                            _SurahActionDockButton(
                              tooltip: 'Settings',
                              assetPath: useAssetIcons
                                  ? 'assets/icons/settings-img.png'
                                  : null,
                              icon: useAssetIcons ? null : Icons.settings_outlined,
                              onPressed: onSettingsPressed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahActionDockButton extends StatelessWidget {
  const _SurahActionDockButton({
    required this.tooltip,
    this.icon,
    this.assetPath,
    required this.onPressed,
  });

  final String tooltip;
  final IconData? icon;
  final String? assetPath;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? Colors.white : AppTheme.appIconTheme;

    final Widget iconWidget = assetPath != null
        ? Image.asset(assetPath!, width: 24, height: 24, color: iconColor)
        : Icon(icon, color: iconColor, size: 24);

    return Expanded(
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: SizedBox(
              height: surahActionDockHeight,
              child: Center(child: iconWidget),
            ),
          ),
        ),
      ),
    );
  }
}