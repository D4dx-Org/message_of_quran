import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';

const double kSettingsSelectorItemHeight = 30;
const double kSettingsSelectorTextHeight = 1.0;
const double kSettingsSelectorVerticalPadding = 2;
const double kSettingsSelectorMenuItemHorizontalPadding = 12;
const double kSettingsSelectorTitleValueGap = 12;
const double kSettingsSelectorPopupMinWidth = 140;
const double kSettingsSelectorMenuIndicatorGap = 8;
const double kSettingsSelectorMenuIndicatorSlotWidth = 18;
const double kSettingsSelectorSelectedValueLeftPadding = 0;
const double kSettingsSelectorSelectedValueRightPadding = 12;
const double kSettingsSelectorPopupElevation = 14;
const int kSettingsSelectorTitleFlex = 5;
const int kSettingsSelectorValueFlex = 4;

double settingsSelectorMenuHeight(int visibleItemCount) {
  return visibleItemCount * kSettingsSelectorItemHeight;
}

double settingsSelectorPopupMaxHeight(int visibleItemCount) {
  return settingsSelectorMenuHeight(visibleItemCount);
}

double settingsSelectorPopupContentWidth({
  required Iterable<String> labels,
  required TextStyle textStyle,
  required TextDirection textDirection,
  required TextScaler textScaler,
}) {
  var widestLabelWidth = 0.0;

  for (final label in labels) {
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      maxLines: 1,
      ellipsis: '...',
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout();

    widestLabelWidth = math.max(widestLabelWidth, textPainter.width);
  }

  return widestLabelWidth +
      (kSettingsSelectorMenuItemHorizontalPadding * 2) +
      kSettingsSelectorMenuIndicatorGap +
      kSettingsSelectorMenuIndicatorSlotWidth;
}

double settingsSelectorPopupWidth({
  required Iterable<String> labels,
  required TextStyle textStyle,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required double maxWidth,
}) {
  if (maxWidth <= 0) {
    return 0;
  }

  final desiredWidth = settingsSelectorPopupContentWidth(
    labels: labels,
    textStyle: textStyle,
    textDirection: textDirection,
    textScaler: textScaler,
  );
  final minWidth = math.min(kSettingsSelectorPopupMinWidth, maxWidth);

  return desiredWidth.clamp(minWidth, maxWidth).toDouble();
}

double settingsSelectorPopupHorizontalOffset({
  required double rowWidth,
  required double popupWidth,
}) {
  return math.max(
    0,
    rowWidth - popupWidth - kSettingsSelectorSelectedValueRightPadding,
  );
}

Color settingsSelectorPopupBackgroundColor(ThemeData theme) {
  return theme.cardColor;
}

Color settingsSelectorPopupShadowColor(Brightness brightness) {
  return Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.34 : 0.2);
}

BorderSide settingsSelectorPopupBorderSide(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return BorderSide.none;
  }

  return BorderSide(
    width: 1.2,
    color: Colors.black.withValues(alpha: 0.1),
  );
}

class SettingsScreenSelectorDropdown<T> extends StatelessWidget {
  const SettingsScreenSelectorDropdown({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    required this.visibleItemCount,
    this.showFullSelectedValue = false,
    this.showFullPopupLabels = false,
  }) : assert(visibleItemCount > 0);

  final String title;
  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T?> onChanged;
  final int visibleItemCount;
  final bool showFullSelectedValue;
  final bool showFullPopupLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = appBarAccentColor(context);
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final titleTextStyle = AppTextTheme.drawerStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
    final selectorTextStyle = AppTextTheme.drawerStyle.copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
      height: kSettingsSelectorTextHeight,
    );
    final popupMeasurementTextStyle = showFullPopupLabels
        ? selectorTextStyle.copyWith(fontWeight: FontWeight.w600)
        : selectorTextStyle;
    final clampedVisibleCount = items.length < visibleItemCount
        ? items.length
        : visibleItemCount;
    final labels = items.map(labelBuilder).toList(growable: false);
    final selectedLabel = labelBuilder(value);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final popupWidth = settingsSelectorPopupWidth(
            labels: labels,
            textStyle: popupMeasurementTextStyle,
            textDirection: textDirection,
            textScaler: textScaler,
            maxWidth: math.max(
              0,
              constraints.maxWidth - kSettingsSelectorSelectedValueRightPadding,
            ),
          );
          final popupConstraints = BoxConstraints(
            minWidth: popupWidth,
            maxWidth: popupWidth,
            maxHeight: settingsSelectorPopupMaxHeight(clampedVisibleCount),
          );
          final popupOffset = Offset(
            settingsSelectorPopupHorizontalOffset(
              rowWidth: constraints.maxWidth,
              popupWidth: popupWidth,
            ),
            8,
          );

          return SizedBox(
            width: constraints.maxWidth,
            child: PopupMenuButton<T>(
              initialValue: value,
              onSelected: (item) => onChanged(item),
              position: PopupMenuPosition.under,
              offset: popupOffset,
              clipBehavior: Clip.antiAlias,
              elevation: kSettingsSelectorPopupElevation,
              shadowColor: settingsSelectorPopupShadowColor(theme.brightness),
              padding: EdgeInsets.zero,
              menuPadding: EdgeInsets.zero,
              constraints: popupConstraints,
              color: settingsSelectorPopupBackgroundColor(theme),
              surfaceTintColor: settingsSelectorPopupBackgroundColor(theme),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: settingsSelectorPopupBorderSide(theme.brightness),
              ),
              itemBuilder: (context) {
                return items
                    .map(
                      (item) {
                        final isSelected = item == value;

                        return PopupMenuItem<T>(
                          value: item,
                          height: kSettingsSelectorItemHeight,
                          padding: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSettingsSelectorMenuItemHorizontalPadding,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    labelBuilder(item),
                                    maxLines: 1,
                                    overflow: showFullPopupLabels
                                      ? null
                                      : TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                    style: selectorTextStyle.copyWith(
                                      color: isSelected
                                          ? accentColor
                                          : theme.colorScheme.onSurface,
                                      fontWeight:
                                          isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: kSettingsSelectorMenuIndicatorGap),
                                SizedBox(
                                  width: kSettingsSelectorMenuIndicatorSlotWidth,
                                  child: isSelected
                                      ? Align(
                                          alignment: AlignmentDirectional.centerEnd,
                                          child: Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: accentColor,
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                    .toList(growable: false);
              },
              child: Padding(
                padding: const EdgeInsets.only(
                  left: kSettingsSelectorSelectedValueLeftPadding,
                  right: kSettingsSelectorSelectedValueRightPadding,
                  top: kSettingsSelectorVerticalPadding,
                  bottom: kSettingsSelectorVerticalPadding,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: accentColor, size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: kSettingsSelectorTitleFlex,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleTextStyle,
                      ),
                    ),
                    const SizedBox(width: kSettingsSelectorTitleValueGap),
                    Expanded(
                      flex: kSettingsSelectorValueFlex,
                      child: Row(
                        children: [
                          Expanded(
                            child: showFullSelectedValue
                                ? Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: Text(
                                        selectedLabel,
                                        maxLines: 1,
                                        textAlign: TextAlign.end,
                                        style: selectorTextStyle,
                                      ),
                                    ),
                                  )
                                : Text(
                                    selectedLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: selectorTextStyle,
                                  ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: theme.colorScheme.onSurface,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}