import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/features/about_screen/presentation/about_screen.dart';
import 'package:the_message_of_the_quran/features/about_screen/provider/about_providers.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_language': LanguageProvider.english,
    });
  });

  testWidgets('shows only the no data state when about content is unavailable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AboutProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const MaterialApp(home: AboutScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final noDataText = tester.widget<Text>(find.text('No Data'));

    expect(find.text('No Data'), findsOneWidget);
    expect(noDataText.textAlign, TextAlign.center);
    expect(find.text(ApiConstants.bookplusUrl), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}