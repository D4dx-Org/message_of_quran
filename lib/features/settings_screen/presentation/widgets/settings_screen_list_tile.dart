import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';

class SettingsScreenListTile extends StatelessWidget {
  const SettingsScreenListTile({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
  });
  final String title;
  final IconData icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      horizontalTitleGap: 16,
      tileColor: Colors.transparent,
      leading: Icon(icon, color: AppTheme.appIconTheme),
      title: Text(
        title,
        style: AppTextTheme.drawerStyle.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: trailing,
    );
  }
}
