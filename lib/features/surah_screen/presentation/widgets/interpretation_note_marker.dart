import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';

InlineSpan buildInterpretationNoteMarkerSpan({
  required int number,
  required VoidCallback onTap,
}) {
  return WidgetSpan(
    alignment: PlaceholderAlignment.aboveBaseline,
    baseline: TextBaseline.alphabetic,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -2),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 2),
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final circleColor = isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.appThemePrimary;
              final textColor = isDark
                  ? const Color(0xff103564)
                  : Colors.white;
              return Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
    ),
  );
}
