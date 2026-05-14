import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';

InlineSpan buildInterpretationNoteMarkerSpan({
  required int number,
  required VoidCallback onTap,
}) {
  return WidgetSpan(
    alignment: PlaceholderAlignment.aboveBaseline,
    baseline: TextBaseline.alphabetic,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -4),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 2),
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: AppTheme.appThemePrimary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
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
