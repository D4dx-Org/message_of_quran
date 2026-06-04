import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';

class SettingsScreenSelectorItem<T> {
  const SettingsScreenSelectorItem({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class SettingsScreenSelectorDropdown<T> extends StatelessWidget {
  const SettingsScreenSelectorDropdown({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.items,
    required this.onSelected,
    this.buttonLabelWidth = 120,
    this.menuLabelWidth = 180,
    this.labelTextStyle,
  }) : assert(items.length > 0);

  final String title;
  final IconData icon;
  final T value;
  final List<SettingsScreenSelectorItem<T>> items;
  final ValueChanged<T> onSelected;
  final double buttonLabelWidth;
  final double menuLabelWidth;
  final TextStyle? labelTextStyle;

  @override
  Widget build(BuildContext context) {
    final accentColor = appBarAccentColor(context);
    final surfaceColor = Theme.of(context).colorScheme.onSurface;
    final baseLabelStyle =
        labelTextStyle ??
        AppTextTheme.drawerStyle.copyWith(fontWeight: FontWeight.w500);
    final defaultLabelStyle = baseLabelStyle.copyWith(color: surfaceColor);
    final selectedLabelStyle = baseLabelStyle.copyWith(
      color: accentColor,
      fontWeight: FontWeight.w600,
    );
    final selectedItem = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.first,
    );

    return SettingsScreenListTile(
      title: title,
      icon: icon,
      trailing: PopupMenuButton<T>(
        initialValue: value,
        tooltip: title,
        padding: EdgeInsets.zero,
        offset: const Offset(0, 8),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: onSelected,
        itemBuilder: (context) {
          return items.map((item) {
            final isSelected = item.value == value;

            return PopupMenuItem<T>(
              value: item.value,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: menuLabelWidth),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: isSelected
                              ? selectedLabelStyle
                              : defaultLabelStyle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    child: isSelected
                        ? Icon(Icons.check, size: 16, color: accentColor)
                        : null,
                  ),
                ],
              ),
            );
          }).toList();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonLabelWidth,
              child: Text(
                selectedItem.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: selectedLabelStyle,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: accentColor),
          ],
        ),
      ),
    );
  }
}