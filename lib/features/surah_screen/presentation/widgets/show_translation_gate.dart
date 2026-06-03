import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';

class ShowTranslationGate extends StatelessWidget {
  const ShowTranslationGate({
    super.key,
    required this.hasTranslation,
    required this.builder,
  });

  final bool hasTranslation;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final showTranslation = context.select<PlaySettingsProvider, bool>(
      (playSettings) => playSettings.showTranslation,
    );
    if (!hasTranslation || !showTranslation) {
      return const SizedBox.shrink();
    }
    return builder(context);
  }
}