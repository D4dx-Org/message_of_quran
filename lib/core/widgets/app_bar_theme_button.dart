import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';

const Color _accent = Color(0xFFF2F2F7);

/// Icon button placed in app bars to toggle between light and dark mode.
/// Matches the visual style of [AppBarLanguageButton].
class AppBarThemeToggleButton extends StatefulWidget {
  const AppBarThemeToggleButton({super.key, this.iconSize = 15});

  final double iconSize;

  @override
  State<AppBarThemeToggleButton> createState() =>
      _AppBarThemeToggleButtonState();
}

class _AppBarThemeToggleButtonState extends State<AppBarThemeToggleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final hoverBgColor = _accent.withValues(alpha: 0.14);
    final hoverBorderColor = _accent.withValues(alpha: 0.24);

    return Semantics(
      button: true,
      label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: GestureDetector(
        onTap: () => themeProvider.toggleTheme(),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: _isHovered ? hoverBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _isHovered ? hoverBorderColor : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: widget.iconSize,
                  color: _accent,
                ),
                // Match the 1.5 px underline spacer used by other nav items
                const SizedBox(height: 2),
                const SizedBox(height: 1.5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
