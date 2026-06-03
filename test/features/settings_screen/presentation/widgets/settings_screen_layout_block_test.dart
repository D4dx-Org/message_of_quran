import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_layout_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLayoutBlock(
    WidgetTester tester, {
    required String languageCode,
  }) async {
    SharedPreferences.setMockInitialValues({'app_language': languageCode});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => FontSizeChangerProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreenLayoutBlock()),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('shows translation justify toggle in English', (tester) async {
    await pumpLayoutBlock(tester, languageCode: LanguageProvider.english);

    expect(find.text('Justify Translation'), findsOneWidget);
    expect(find.text('Justify Interpretation'), findsOneWidget);
    expect(find.text('Justify Quran Ayahs & Tajweed'), findsOneWidget);
  });

  testWidgets('hides translation and interpretation justify toggles in Malayalam',
      (tester) async {
    await pumpLayoutBlock(tester, languageCode: LanguageProvider.malayalam);

    expect(find.text('Justify Translation'), findsNothing);
    expect(find.text('Justify Interpretation'), findsNothing);
    expect(find.text('Justify Quran Ayahs & Tajweed'), findsOneWidget);
  });
}
