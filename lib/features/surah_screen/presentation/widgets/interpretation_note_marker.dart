import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';

/// The badge is only as big as a superscript, which is a hard thing to hit
/// for an older reader. The circle stays close to its drawn size, but the
/// span around it is padded out into a proper touch target: as tall as the
/// line it sits on, and wider than the badge on either side, so the tap is
/// forgiving without tearing gaps into the paragraph.
InlineSpan buildInterpretationNoteMarkerSpan({
  required int number,
  required VoidCallback onTap,
}) {
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final circleColor = isDark
            ? Colors.white.withValues(alpha: 0.7)
            : AppTheme.appThemePrimary;
        final textColor = isDark ? const Color(0xff103564) : Colors.white;

        // Everything scales with the reader's own text size, so a reader who
        // has turned the text up gets a bigger badge to aim at as well.
        final fontSize = AppTextTheme.contentFontSize(context);
        final diameter = (fontSize * 1.15).clamp(20.0, 30.0);
        final touchHeight = (fontSize * 1.9).clamp(34.0, 48.0);
        final touchWidth = diameter + 24;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: touchWidth,
            height: touchHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Transform.translate(
                  // Keeps the raised, superscript look now that the touch
                  // target is centred on the line.
                  offset: Offset(0, -fontSize * 0.12),
                  child: Container(
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$number',
                          style: TextStyle(
                            fontSize: diameter * 0.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            height: 1,
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
      },
    ),
  );
}
