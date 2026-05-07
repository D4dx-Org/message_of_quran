import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_audio_block.dart';

class SettingsAudioTab extends StatelessWidget {
  const SettingsAudioTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: const [
        SettingsScreenAudioBlock(),
        SizedBox(height: 32),
      ],
    );
  }
}
