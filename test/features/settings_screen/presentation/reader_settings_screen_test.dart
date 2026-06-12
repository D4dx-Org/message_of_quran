import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/reader_settings_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/reminder_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/tajweed_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/wakelock_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class _UnsupportedReminderProvider extends ReminderProvider {
  @override
  bool get isSupported => false;
}

class _UnsupportedWakelockProvider extends WakelockProvider {
  @override
  bool get isSupported => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpReaderSettingsHost(WidgetTester tester) async {
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => themeProvider),
          ChangeNotifierProvider(create: (_) => SurahProvider()),
          ChangeNotifierProvider(create: (_) => FontSizeChangerProvider()),
          ChangeNotifierProvider(create: (_) => PlaySettingsProvider()),
          ChangeNotifierProvider(create: (_) => TajweedProvider()),
          ChangeNotifierProvider(create: (_) => _UnsupportedReminderProvider()),
          ChangeNotifierProvider(create: (_) => _UnsupportedWakelockProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReaderSettingsScreen(),
                        ),
                      );
                    },
                    child: const Text('Open settings'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('reader settings back returns to previous route', (
    WidgetTester tester,
  ) async {
    await pumpReaderSettingsHost(tester);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderSettingsScreen), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ReaderSettingsScreen), findsNothing);
    expect(find.text('Open settings'), findsOneWidget);
  });
}