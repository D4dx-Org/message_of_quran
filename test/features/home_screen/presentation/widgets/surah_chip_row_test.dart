import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/surah_chip_row.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpChipRow(
    WidgetTester tester, {
    bool? useCompactWebLayout,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SurahProvider>.value(
            value: _TestSurahProvider(_sampleSurahs),
          ),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SurahChipRow(
                useCompactWebLayout: useCompactWebLayout,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets(
    'surah chip row uses compact content-sized pills on web',
    (tester) async {
      await pumpChipRow(tester, useCompactWebLayout: true);

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final scrollPadding = scrollView.padding as EdgeInsets;

      expect(scrollView.scrollDirection, Axis.horizontal);
      expect(scrollPadding, const EdgeInsets.symmetric(horizontal: 12));
      expect(find.byType(ListView), findsNothing);
      expect(find.text('Ayatul Kursi'), findsOneWidget);
      expect(find.text('Al-Kahf'), findsOneWidget);

      final ayatulChip = find.ancestor(
        of: find.text('Ayatul Kursi'),
        matching: find.byType(GestureDetector),
      );
      final alKahfChip = find.ancestor(
        of: find.text('Al-Kahf'),
        matching: find.byType(GestureDetector),
      );

      final ayatulChipSize = tester.getSize(ayatulChip);
      final alKahfChipSize = tester.getSize(alKahfChip);
      final ayatulChipContainer = find.descendant(
        of: ayatulChip,
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.padding == const EdgeInsets.all(6),
        ),
      );

      expect(ayatulChipContainer, findsOneWidget);
      expect(ayatulChipSize.height, lessThan(40));
      expect(alKahfChipSize.height, equals(ayatulChipSize.height));
      expect(ayatulChipSize.width, greaterThan(alKahfChipSize.width));
    },
  );

  testWidgets(
    'surah chip row keeps the original mobile list layout by default',
    (tester) async {
      await pumpChipRow(tester, useCompactWebLayout: false);

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ListView),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.height, 40);
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
  _surah(18, 'Al-Kahf', 'The Cave'),
  _surah(36, 'Ya-Sin', 'Ya Sin'),
  _surah(55, 'Ar-Rahman', 'The Beneficent'),
  _surah(56, 'Al-Waqiah', 'The Inevitable'),
  _surah(67, 'Al-Mulk', 'The Sovereignty'),
];

SurahModel _surah(int number, String name, String description) {
  return SurahModel(
    id: '$number',
    surahNumber: number,
    name: name,
    searchName: name.toLowerCase(),
    arabicName: name,
    malayalamName: name,
    description: description,
    ayathCount: 10,
    place: 'Makkah',
    createdBy: '',
    createdByRole: '',
    isVerified: true,
  );
}