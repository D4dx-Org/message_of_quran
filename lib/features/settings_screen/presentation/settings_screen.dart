import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_app_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_audio_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_dark_mode_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_language_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_quran_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_tajweed_block.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      child: CustomScrollView(
        slivers: [
          // SliverAppBar(
          //   pinned: true,
          //   automaticallyImplyLeading: false,
          //   title: Text(
          //     'Settings',
          //     style: theme.textTheme.titleLarge?.copyWith(
          //       fontWeight: FontWeight.w700,
          //     ),
          //   ),
          // ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.list(
              children: const [
                SizedBox(height: 20),
                _SectionLabel('Language'),
                SizedBox(height: 8),
                SettingsScreenLanguageBlock(),
                SizedBox(height: 20),
                _SectionLabel('Appearance'),
                SizedBox(height: 8),
                SettingsScreenDarkModeBlock(),
                SizedBox(height: 20),
                _SectionLabel("Qur'an"),
                SizedBox(height: 8),
                SettingsScreenQuranBlock(),
                SizedBox(height: 20),
                _SectionLabel('Tajweed'),
                SizedBox(height: 8),
                SettingsScreenTajweedBlock(),
                SizedBox(height: 20),
                _SectionLabel('Audio'),
                SizedBox(height: 8),
                SettingsScreenAudioBlock(),
                SizedBox(height: 20),
                _SectionLabel('App'),
                SizedBox(height: 8),
                SettingsScreenAppBlock(),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }
}

