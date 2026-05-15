import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/models/juz_hizb_model.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/home_screen.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_list.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpHomeTile(
    WidgetTester tester, {
    String languageCode = LanguageProvider.english,
    int index = 0,
  }) async {
    SharedPreferences.setMockInitialValues({
      'app_language': languageCode,
    });
    final surahProvider = _TestSurahProvider(_sampleSurahs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SurahProvider>.value(value: surahProvider),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => LastReadProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HomeScreenListTile(index: index),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> pumpHomeScreen(
    WidgetTester tester, {
    String languageCode = LanguageProvider.english,
  }) async {
    SharedPreferences.setMockInitialValues({
      'app_language': languageCode,
    });
    final surahProvider = _TestSurahProvider(_sampleSurahs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SurahProvider>.value(value: surahProvider),
          ChangeNotifierProvider(
            create: (_) => JuzHizbProvider()..juzList = _sampleJuz,
          ),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => LastReadProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets(
    'home screen shows Surah and Juz tabs with Surah selected by default',
    (tester) async {
      await pumpHomeScreen(tester);

      expect(find.byType(HomeScreenList), findsOneWidget);
      final listView = tester.widget<ListView>(
        find.descendant(
          of: find.byType(HomeScreenList),
          matching: find.byType(ListView),
        ),
      );
      final padding = listView.padding! as EdgeInsets;

      expect(find.text('Surah'), findsOneWidget);
      expect(find.text("Juz'e"), findsOneWidget);
      expect(find.text('Al-Fatihah'), findsOneWidget);
      expect(find.text('Hizb'), findsNothing);
      expect(find.text('ഹിസ്ബ്'), findsNothing);
      expect(padding.top, 0);
    },
  );

  testWidgets(
    'home screen switches to the Juz tab and shows Juz list content',
    (tester) async {
      await pumpHomeScreen(tester);

      expect(find.text('Juz 1'), findsNothing);

      await tester.tap(find.text("Juz'e"));
      await tester.pumpAndSettle();

      expect(find.text('Al-Fatihah'), findsOneWidget);
      expect(find.text('The Opening'), findsOneWidget);
      expect(find.text('AYAH 1'), findsOneWidget);
      expect(find.text('7 Ayahs'), findsNothing);
      expect(find.text('Makkah'), findsNothing);
      expect(find.text('SURAH 1  •  AYAH 1'), findsNothing);
    },
  );

  testWidgets(
    'home screen Juz tab uses the same ayah color as Surah tile metadata',
    (tester) async {
      await pumpHomeTile(tester);

      final homeAyahText = tester.widget<Text>(find.text('7 Ayahs'));
      final expectedAyahColor = homeAyahText.style?.color;

      expect(expectedAyahColor, isNotNull);

      await pumpHomeScreen(tester);
      await tester.tap(find.text("Juz'e"));
      await tester.pumpAndSettle();

      final juzAyahText = tester.widget<Text>(find.text('AYAH 1'));

      expect(juzAyahText.style?.color, expectedAyahColor);
    },
  );

  testWidgets(
    'home screen Juz tab keeps the surah-style metadata layout in Malayalam',
    (tester) async {
      await pumpHomeScreen(
        tester,
        languageCode: LanguageProvider.malayalam,
      );

      await tester.tap(find.text('ജുസ്'));
      await tester.pumpAndSettle();

      expect(find.text('അല്\u200d-ഫാതിഹ'), findsOneWidget);
      expect(find.text('The Opening'), findsOneWidget);
      expect(find.text('ആയത്ത് 1'), findsOneWidget);
      expect(find.text('7 ആയത്ത്'), findsNothing);
      expect(find.text('Makkah'), findsNothing);
    },
  );

  testWidgets(
    'home tile shows translation meaning and trailing English metadata without Arabic name',
    (tester) async {
      await pumpHomeTile(tester);

      expect(find.text('Al-Fatihah'), findsOneWidget);
      expect(find.text('The Opening'), findsOneWidget);
      expect(find.text('Makkah'), findsOneWidget);
      expect(find.text('7 Ayahs'), findsOneWidget);
      expect(find.text('الفاتحة'), findsNothing);
    },
  );

  testWidgets(
    'home tile keeps Malayalam labels while showing the translation meaning',
    (tester) async {
      await pumpHomeTile(
        tester,
        languageCode: LanguageProvider.malayalam,
        index: 1,
      );

      expect(find.text('അല്‍-ബഖറ'), findsOneWidget);
      expect(find.text('The Cow'), findsOneWidget);
      expect(find.text('Madinah'), findsOneWidget);
      expect(find.text('286 ആയത്ത്'), findsOneWidget);
      expect(find.text('البقرة'), findsNothing);
    },
  );
}

class _TestSurahProvider extends SurahProvider {
  _TestSurahProvider(List<SurahModel> surahs) {
    surahList = surahs;
    isSurahLoading = false;
  }

  @override
  Future<void> loadBookmarks() async {}
}

final List<SurahModel> _sampleSurahs = [
  SurahModel(
    id: '1',
    surahNumber: 1,
    name: 'Al-Fatihah',
    searchName: 'al-fatihah',
    arabicName: 'الفاتحة',
    malayalamName: 'അല്‍-ഫാതിഹ',
    description: 'The Opening',
    ayathCount: 7,
    place: 'Makkah',
    createdBy: '',
    createdByRole: '',
    isVerified: true,
  ),
  SurahModel(
    id: '2',
    surahNumber: 2,
    name: 'Al-Baqarah',
    searchName: 'al-baqarah',
    arabicName: 'البقرة',
    malayalamName: 'അല്‍-ബഖറ',
    description: 'The Cow',
    ayathCount: 286,
    place: 'Madinah',
    createdBy: '',
    createdByRole: '',
    isVerified: true,
  ),
];

final List<JuzHizbModel> _sampleJuz = [
  JuzHizbModel(
    id: 1,
    number: 1,
    surahNumber: 1,
    ayahNumber: 1,
  ),
  JuzHizbModel(
    id: 2,
    number: 2,
    surahNumber: 2,
    ayahNumber: 142,
  ),
];