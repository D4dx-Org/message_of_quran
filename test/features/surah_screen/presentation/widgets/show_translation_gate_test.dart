import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/show_translation_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows and hides translation content as the setting changes', (
    tester,
  ) async {
    final playSettings = PlaySettingsProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<PlaySettingsProvider>.value(
        value: playSettings,
        child: MaterialApp(
          home: Scaffold(
            body: ShowTranslationGate(
              hasTranslation: true,
              builder: (_) => const Text('Translation text'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Translation text'), findsOneWidget);

    await playSettings.setShowTranslation(false);
    await tester.pumpAndSettle();

    expect(find.text('Translation text'), findsNothing);

    await playSettings.setShowTranslation(true);
    await tester.pumpAndSettle();

    expect(find.text('Translation text'), findsOneWidget);
  });

  testWidgets('keeps translation hidden when no translation exists', (tester) async {
    final playSettings = PlaySettingsProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<PlaySettingsProvider>.value(
        value: playSettings,
        child: MaterialApp(
          home: Scaffold(
            body: ShowTranslationGate(
              hasTranslation: false,
              builder: (_) => const Text('Translation text'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Translation text'), findsNothing);
  });
}