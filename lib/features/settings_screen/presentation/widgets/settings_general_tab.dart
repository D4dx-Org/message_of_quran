import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_app_block.dart';

class SettingsGeneralTab extends StatelessWidget {
  const SettingsGeneralTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: const [
        SettingsScreenAppBlock(),
        SizedBox(height: 32),
      ],
    );
  }
}
