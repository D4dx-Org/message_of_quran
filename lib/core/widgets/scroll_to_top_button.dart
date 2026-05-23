import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';

/// A button that animates in/out based on [visible].
/// Tap it to invoke [onPressed] (typically animate the scroll controller to 0).
class ScrollToTopButton extends StatelessWidget {
  final bool visible;
  final VoidCallback onPressed;
  final String heroTag;

  const ScrollToTopButton({
    super.key,
    required this.visible,
    required this.onPressed,
    this.heroTag = 'scrollToTop',
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDarkMode
        ? Theme.of(context).cardColor
        : const Color.fromRGBO(255, 250, 234, 1);
    final iconColor = isDarkMode ? Colors.white : AppTheme.appIconTheme;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.18)
        : AppTheme.appIconTheme.withValues(alpha: 0.24);

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !visible,
        child: Tooltip(
          message: 'Scroll to top',
          child: Material(
            color: buttonColor,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPressed,
              child: SizedBox(
                width: 34,
                height: 34,
                child: Icon(Icons.keyboard_arrow_up_rounded, color: iconColor, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
