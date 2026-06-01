import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';

class SettingsScreenListTile extends StatelessWidget {
  const SettingsScreenListTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final accentColor = appBarAccentColor(context);

    return ListTile(
      horizontalTitleGap: 16,
      tileColor: Colors.transparent,
      leading: Icon(icon, color: accentColor),
      title: Text(
        title,
        style: AppTextTheme.drawerStyle.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: trailing,
    );
  }
}
