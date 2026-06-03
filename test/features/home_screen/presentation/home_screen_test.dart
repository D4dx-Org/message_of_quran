import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/models/juz_hizb_model.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/home_screen.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_list_row_text_styles.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_list.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/star_number.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder findJuzStar(int number) => find.byWidgetPredicate(
    (widget) => widget is StarNumber && widget.number == number,
  );

  void expectMatchingTextStyle(Text actual, Text expected) {
    expect(actual.style, isNotNull);
    expect(expected.style, isNotNull);
    expect(actual.style?.color, expected.style?.color);
    expect(actual.style?.fontSize, expected.style?.fontSize);
    expect(actual.style?.fontWeight, expected.style?.fontWeight);
    expect(actual.style?.letterSpacing, expected.style?.letterSpacing);
    expect(actual.style?.height, expected.style?.height);
  }

  void expectMatchingStyleFields(Text actual, Text expected) {
    expect(actual.style, isNotNull);
    expect(expected.style, isNotNull);
    expect(actual.style!.color, expected.style!.color);
    expect(actual.style!.fontSize, expected.style!.fontSize);
    expect(actual.style!.fontWeight, expected.style!.fontWeight);
    expect(actual.style!.letterSpacing, expected.style!.letterSpacing);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpHomeTile(
    WidgetTester tester, {
    String languageCode = LanguageProvider.english,
    int index = 0,
    List<SurahModel>? surahs,
  }) async {
    SharedPreferences.setMockInitialValues({'app_language': languageCode});
    final surahProvider = _TestSurahProvider(surahs ?? _sampleSurahs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SurahProvider>.value(value: surahProvider),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => LastReadProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(body: HomeScreenListTile(index: index)),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> pumpHomeScreen(
    WidgetTester tester, {
    String languageCode = LanguageProvider.english,
    Map<String, Object> initialPreferences = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      ...initialPreferences,
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
        child: const MaterialApp(home: HomeScreen()),
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
    'home screen applies an elevated shadow to the outer rounded content card',
    (tester) async {
      await pumpHomeScreen(tester);

      final cardContainer = tester.widget<Container>(
        find.byWidgetPredicate((widget) {
          if (widget is! Container) {
            return false;
          }
          final decoration = widget.decoration;
          if (decoration is! BoxDecoration) {
            return false;
          }
          final borderRadius = decoration.borderRadius;
          if (borderRadius is! BorderRadius) {
            return false;
          }

          return borderRadius.topLeft == const Radius.circular(70) &&
              borderRadius.topRight == const Radius.circular(70) &&
              decoration.boxShadow?.length == 1;
        }),
      );
      final decoration = cardContainer.decoration! as BoxDecoration;
      final shadow = decoration.boxShadow!.single;

      expect(shadow.offset, const Offset(0, -3));
      expect(shadow.blurRadius, 16);
      expect(shadow.spreadRadius, 1);
      expect(shadow.color.a, closeTo(0.10, 0.01));
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
      expect(find.text('Ayah 1'), findsOneWidget);
      expect(find.text('7 Ayahs'), findsNothing);
      expect(find.text('Makkah'), findsNothing);
      expect(find.text('SURAH 1  •  Ayah 1'), findsNothing);
    },
  );

  testWidgets(
    'home screen Juz tab uses the same ayah text style as Surah tile metadata',
    (tester) async {
      await pumpHomeTile(tester);

      final homeAyahText = tester.widget<Text>(find.text('7 Ayahs'));
      final expectedAyahStyle = homeAyahText.style;

      expect(expectedAyahStyle, isNotNull);

      await pumpHomeScreen(tester);
      await tester.tap(find.text("Juz'e"));
      await tester.pumpAndSettle();

      final juzAyahText = tester.widget<Text>(find.text('Ayah 1'));
      final actualAyahStyle = juzAyahText.style;

      expect(actualAyahStyle, isNotNull);
      expect(actualAyahStyle?.color, expectedAyahStyle?.color);
      expect(actualAyahStyle?.fontSize, expectedAyahStyle?.fontSize);
      expect(actualAyahStyle?.fontWeight, expectedAyahStyle?.fontWeight);
      expect(
        actualAyahStyle?.letterSpacing,
        expectedAyahStyle?.letterSpacing,
      );
    },
  );

  testWidgets(
    'home screen Juz tab matches Surah tile title and subtitle typography',
    (tester) async {
      await pumpHomeTile(tester);

      final homeTitleText = tester.widget<Text>(find.text('Al-Fatihah'));
      final homeSubtitleText = tester.widget<Text>(find.text('The Opening'));

      await pumpHomeScreen(tester);
      await tester.tap(find.text("Juz'e"));
      await tester.pumpAndSettle();

      final juzTitleText = tester.widget<Text>(find.text('Al-Fatihah'));
      final juzSubtitleText = tester.widget<Text>(find.text('The Opening'));

      expectMatchingTextStyle(juzTitleText, homeTitleText);
      expectMatchingTextStyle(juzSubtitleText, homeSubtitleText);
    },
  );

  testWidgets(
    'home screen Juz tab uses the same top padding as the Surah list',
    (tester) async {
      await pumpHomeScreen(tester);

      final surahListView = tester.widget<ListView>(
        find.descendant(
          of: find.byType(HomeScreenList),
          matching: find.byType(ListView),
        ),
      );

      await tester.tap(find.text("Juz'e"));
      await tester.pumpAndSettle();

      final juzListView = tester.widget<ListView>(find.byType(ListView).last);
      final surahPadding = surahListView.padding! as EdgeInsets;
      final juzPadding = juzListView.padding! as EdgeInsets;

      expect(surahPadding.top, homeListTopPadding);
      expect(juzPadding.top, surahPadding.top);
    },
  );

  testWidgets(
    'home screen Juz tab uses the same title and subtitle styles as Surah tiles',
    (tester) async {
      await pumpHomeTile(tester);

      final homeTitleText = tester.widget<Text>(find.text('Al-Fatihah'));
      final homeSubtitleText = tester.widget<Text>(find.text('The Opening'));

      await pumpHomeScreen(tester);
      await tester.tap(find.text("Juz'e"));
      await tester.pumpAndSettle();

      final juzTitleText = tester.widget<Text>(find.text('Al-Fatihah'));
      final juzSubtitleText = tester.widget<Text>(find.text('The Opening'));

      expectMatchingStyleFields(juzTitleText, homeTitleText);
      expectMatchingStyleFields(juzSubtitleText, homeSubtitleText);
    },
  );

  testWidgets('home screen Juz tab fills the persisted selected Juz', (
    tester,
  ) async {
    await pumpHomeScreen(
      tester,
      initialPreferences: const {'selected_juz_number': 2},
    );

    await tester.tap(find.text("Juz'e"));
    await tester.pumpAndSettle();

    expect(findJuzStar(1), findsOneWidget);
    expect(findJuzStar(2), findsOneWidget);
    expect(tester.widget<StarNumber>(findJuzStar(1)).isHighlighted, isFalse);
    expect(tester.widget<StarNumber>(findJuzStar(2)).isHighlighted, isTrue);
  });

  testWidgets(
    'home screen Juz tab keeps the surah-style metadata layout in Malayalam',
    (tester) async {
      await pumpHomeScreen(tester, languageCode: LanguageProvider.malayalam);

      await tester.tap(find.text('ജുസ്'));
      await tester.pumpAndSettle();

      expect(find.text('അല്\u200d-ഫാതിഹ'), findsOneWidget);
      expect(find.text('പ്രാരംഭം'), findsNothing);
      expect(find.text('അല്\u200d-ഫാതിഹ (പ്രാരംഭം)'), findsNothing);
      expect(find.text('അല്‍-ബഖറ'), findsOneWidget);
      expect(find.text('പശു'), findsNothing);
      expect(find.text('അല്‍-ബഖറ (പശു)'), findsNothing);
      expect(find.text('The Opening'), findsNothing);
      expect(find.text('The Cow'), findsNothing);
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

  testWidgets('home tile keeps English uncertain label without period prefix', (
    tester,
  ) async {
    await pumpHomeTile(
      tester,
      surahs: [
        SurahModel(
          id: '4',
          surahNumber: 4,
          name: 'An-Nisa',
          searchName: 'an-nisa',
          arabicName: 'النساء',
          malayalamName: 'അന്‍-നിസാ',
          description: 'The Women',
          ayathCount: 176,
          place: 'Period Uncertain',
          createdBy: '',
          createdByRole: '',
          isVerified: true,
        ),
      ],
    );

    expect(find.text('An-Nisa'), findsOneWidget);
    expect(find.text('The Women'), findsOneWidget);
    expect(find.text('Uncertain'), findsOneWidget);
    expect(find.text('Period Uncertain'), findsNothing);
    expect(find.text('176 Ayahs'), findsOneWidget);
  });

  testWidgets('home tile uses tighter vertical spacing around the divider', (
    tester,
  ) async {
    await pumpHomeTile(tester);

    final tilePaddingFinder = find.descendant(
      of: find.byType(HomeScreenListTile),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding ==
                const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
    );
    final dividerGapFinder = find.descendant(
      of: find.byType(HomeScreenListTile),
      matching: find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 6,
      ),
    );

    expect(tilePaddingFinder, findsOneWidget);
    expect(dividerGapFinder, findsOneWidget);
  });

  testWidgets(
    'home tile shows the localized Malayalam name for Surah 1',
    (tester) async {
      await pumpHomeTile(tester, languageCode: LanguageProvider.malayalam);

      expect(find.text('അല്‍-ഫാതിഹ'), findsOneWidget);
      expect(find.text('പ്രാരംഭം'), findsNothing);
      expect(find.text('അല്‍-ഫാതിഹ (പ്രാരംഭം)'), findsNothing);
      expect(find.text('മക്ക'), findsOneWidget);
      expect(find.text('7 ആയത്ത്'), findsOneWidget);
      expect(find.text('The Opening'), findsNothing);
    },
  );

  testWidgets(
    'home tile shows the localized Malayalam name for Surah 2',
    (tester) async {
      await pumpHomeTile(
        tester,
        languageCode: LanguageProvider.malayalam,
        index: 1,
      );

      expect(find.text('അല്‍-ബഖറ'), findsOneWidget);
        expect(find.text('പശു'), findsNothing);
      expect(find.text('അല്‍-ബഖറ (പശു)'), findsNothing);
      expect(find.text('The Cow'), findsNothing);
      expect(find.text('മദീന'), findsOneWidget);
      expect(find.text('286 ആയത്ത്'), findsOneWidget);
      expect(find.text('البقرة'), findsNothing);
    },
  );

  testWidgets(
    'home tile keeps long Malayalam period labels visible on one line',
    (tester) async {
      await pumpHomeTile(
        tester,
        languageCode: LanguageProvider.malayalam,
        index: 2,
      );

      expect(find.text('ആലു ഇംറാൻ'), findsOneWidget);
      expect(find.text('Family of Imran'), findsNothing);
      expect(find.text('ആലു ഇംറാൻ (Family of Imran)'), findsNothing);
      final placeText = tester.widget<Text>(find.text('കാലഘട്ടം അവ്യക്തം'));

      expect(find.text('കാലഘട്ടം അവ്യക്തം'), findsOneWidget);
      expect(find.text('200 ആയത്ത്'), findsOneWidget);
      expect(placeText.maxLines, 1);
      expect(placeText.softWrap, isFalse);
      expect(placeText.overflow, isNull);
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
  SurahModel(
    id: '3',
    surahNumber: 3,
    name: 'Aal-e-Imran',
    searchName: 'aal-e-imran',
    arabicName: 'آل عمران',
    malayalamName: 'ആലു ഇംറാൻ',
    description: 'Family of Imran',
    ayathCount: 200,
    place: 'കാലഘട്ടം അവ്യക്തം',
    createdBy: '',
    createdByRole: '',
    isVerified: true,
  ),
];

final List<JuzHizbModel> _sampleJuz = [
  JuzHizbModel(id: 1, number: 1, surahNumber: 1, ayahNumber: 1),
  JuzHizbModel(id: 2, number: 2, surahNumber: 2, ayahNumber: 142),
];
