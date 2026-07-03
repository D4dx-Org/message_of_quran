import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/platform_helper.dart';

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

class SettingsScreenSelectorDropdown<T> extends StatefulWidget {
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
  State<SettingsScreenSelectorDropdown<T>> createState() =>
      _SettingsScreenSelectorDropdownState<T>();
}

class _SettingsScreenSelectorDropdownState<T>
    extends State<SettingsScreenSelectorDropdown<T>> {
  final _anchorKey = GlobalKey();

  void _showMenu({
    required double popupWidth,
    required BoxConstraints popupConstraints,
    required int itemCount,
  }) {
    final anchorBox = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (anchorBox == null || overlayBox == null) return;

    final anchorTopLeft = anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final anchorSize = anchorBox.size;
    final screenHeight = overlayBox.size.height;

    const gap = 8.0;
    final popupHeight = math.min(
      settingsSelectorPopupMaxHeight(itemCount),
      screenHeight - gap * 2,
    );

    final spaceBelow = screenHeight - (anchorTopLeft.dy + anchorSize.height) - gap;
    final spaceAbove = anchorTopLeft.dy - gap;
    final openBelow = spaceBelow >= popupHeight || spaceBelow >= spaceAbove;

    final top = openBelow
        ? anchorTopLeft.dy + anchorSize.height + gap
        : math.max(gap, anchorTopLeft.dy - popupHeight - gap);
    final left = anchorTopLeft.dx + math.max(0, anchorSize.width - popupWidth);

    final theme = Theme.of(context);
    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        left,
        top,
        overlayBox.size.width - left - popupWidth,
        overlayBox.size.height - top - popupHeight,
      ),
      items: _buildMenuItems(context),
      constraints: popupConstraints,
      clipBehavior: Clip.antiAlias,
      elevation: kSettingsSelectorPopupElevation,
      shadowColor: settingsSelectorPopupShadowColor(theme.brightness),
      color: settingsSelectorPopupBackgroundColor(theme),
      surfaceTintColor: settingsSelectorPopupBackgroundColor(theme),
      menuPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: settingsSelectorPopupBorderSide(theme.brightness),
      ),
    ).then((value) {
      if (value != null) widget.onChanged(value);
    });
  }

  List<PopupMenuEntry<T>> _buildMenuItems(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = appBarAccentColor(context);
    final selectorTextStyle = AppTextTheme.drawerStyle.copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
      height: kSettingsSelectorTextHeight,
    );

    return widget.items.map((item) {
      final isSelected = item == widget.value;
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
                  widget.labelBuilder(item),
                  maxLines: 1,
                  overflow:
                      widget.showFullPopupLabels ? null : TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: selectorTextStyle.copyWith(
                    color: isSelected ? accentColor : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    }).toList(growable: false);
  }

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
    final popupMeasurementTextStyle = widget.showFullPopupLabels
        ? selectorTextStyle.copyWith(fontWeight: FontWeight.w600)
        : selectorTextStyle;
    final clampedVisibleCount = widget.items.length < widget.visibleItemCount
        ? widget.items.length
        : widget.visibleItemCount;
    final labels = widget.items.map(widget.labelBuilder).toList(growable: false);
    final selectedLabel = widget.labelBuilder(widget.value);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Match the 640px breakpoint used by the settings dialog itself:
          // below 640 it renders as a near-full-width mobile sheet, so keep
          // the scrollable 4-item popup there; above 640 use the full list.
          final isDesktopLayout =
              PlatformHelper.isWeb && MediaQuery.sizeOf(context).width >= 640;
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
          final popupConstraints = isDesktopLayout
              ? BoxConstraints(minWidth: popupWidth, maxWidth: popupWidth)
              : BoxConstraints(
                  minWidth: popupWidth,
                  maxWidth: popupWidth,
                  maxHeight: settingsSelectorPopupMaxHeight(clampedVisibleCount),
                );

          return SizedBox(
            width: constraints.maxWidth,
            child: InkWell(
              onTap: () => _showMenu(
                popupWidth: popupWidth,
                popupConstraints: popupConstraints,
                itemCount: isDesktopLayout ? widget.items.length : clampedVisibleCount,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: kSettingsSelectorSelectedValueLeftPadding,
                  right: kSettingsSelectorSelectedValueRightPadding,
                  top: kSettingsSelectorVerticalPadding,
                  bottom: kSettingsSelectorVerticalPadding,
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: accentColor, size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: kSettingsSelectorTitleFlex,
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleTextStyle,
                      ),
                    ),
                    const SizedBox(width: kSettingsSelectorTitleValueGap),
                    Expanded(
                      flex: kSettingsSelectorValueFlex,
                      child: Row(
                        key: _anchorKey,
                        children: [
                          Expanded(
                            child: widget.showFullSelectedValue
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