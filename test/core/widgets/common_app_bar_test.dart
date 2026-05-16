import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/widgets/app_bar_language_button.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpHomeAppBar(
    WidgetTester tester, {
    String languageCode = LanguageProvider.english,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    SharedPreferences.setMockInitialValues({'app_language': languageCode});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => SurahProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          home: Builder(
            builder: (context) =>
                Scaffold(appBar: CommonAppBar.homeAppBar(context)),
          ),
        ),
      ),
    );
  }

  Future<void> pumpBrandedAppBar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            appBar: CommonAppBar.appBar(context, showBrandLogo: true),
          ),
        ),
      ),
    );
  }

  Future<void> pumpTitledAppBar(
    WidgetTester tester, {
    required bool centerTitle,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            appBar: CommonAppBar.appBar(
              context,
              title: 'Bookmarks',
              centerTitle: centerTitle,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'home app bar keeps the decorative image asset at the intended position',
    (tester) async {
      await pumpHomeAppBar(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final imageFinder = find.byWidgetPredicate((widget) {
        return widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/home_side_image.png';
      });

      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      final positionedFinder = find.ancestor(
        of: imageFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Positioned && widget.top == -48 && widget.left == 298,
        ),
      );

      expect(positionedFinder, findsOneWidget);
      expect(imageWidget.width, 137);
      expect(imageWidget.height, 146);
      expect(imageWidget.fit, BoxFit.contain);
      expect(imageWidget.color, const Color.fromRGBO(124, 58, 40, 1));
      expect(imageWidget.colorBlendMode, BlendMode.srcIn);

      final logoFinder = find.byWidgetPredicate((widget) {
        return widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/Group-logo.png';
      });

      expect(logoFinder, findsOneWidget);
      expect(find.text('The Message of the Quran'), findsNothing);
      expect(find.text('EN'), findsOneWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isNotNull);
      expect(appBar.actions![0], isA<AppBarLanguageButton>());
      expect(appBar.actions![2], isA<IconButton>());
    },
  );

  testWidgets('home app bar reflects the saved Malayalam language code', (
    tester,
  ) async {
    await pumpHomeAppBar(tester, languageCode: LanguageProvider.malayalam);
    await tester.pumpAndSettle();

    expect(find.text('ML'), findsOneWidget);
  });

  testWidgets(
    'home app bar language button keeps the same accent in light and dark themes',
    (tester) async {
      const expectedAccent = Color(0xFFF2F2F7);
      final expectedFill = expectedAccent.withValues(alpha: 0.10);
      final expectedBorder = expectedAccent.withValues(alpha: 0.45);

      Future<void> expectLanguageButtonAccent(ThemeMode themeMode) async {
        await pumpHomeAppBar(tester, themeMode: themeMode);
        await tester.pumpAndSettle();

        final buttonContainer = tester.widget<Container>(
          find.descendant(
            of: find.byType(AppBarLanguageButton),
            matching: find.byType(Container),
          ),
        );
        final decoration = buttonContainer.decoration! as BoxDecoration;
        final border = decoration.border! as Border;
        final languageIcon = tester.widget<Icon>(
          find.descendant(
            of: find.byType(AppBarLanguageButton),
            matching: find.byIcon(Icons.language_rounded),
          ),
        );
        final languageLabel = tester.widget<Text>(find.text('EN'));

        expect(decoration.color, expectedFill);
        expect(border.top.color, expectedBorder);
        expect(languageIcon.color, expectedAccent);
        expect(languageLabel.style?.color, expectedAccent);
      }

      await expectLanguageButtonAccent(ThemeMode.light);
      await expectLanguageButtonAccent(ThemeMode.dark);
    },
  );

  testWidgets('shared app bar can render the brand logo left aligned', (
    tester,
  ) async {
    await pumpBrandedAppBar(tester);
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final logoFinder = find.byWidgetPredicate((widget) {
      return widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/images/Group-logo.png';
    });

    expect(logoFinder, findsOneWidget);
    expect(appBar.centerTitle, isFalse);
    expect(find.text('The Message of the Quran'), findsNothing);
  });

  testWidgets('shared app bar can center shell tab titles', (tester) async {
    await pumpTitledAppBar(tester, centerTitle: true);
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(find.text('Bookmarks'), findsOneWidget);
    expect(appBar.centerTitle, isTrue);
  });

  testWidgets('shared app bar can left align secondary screen titles', (
    tester,
  ) async {
    await pumpTitledAppBar(tester, centerTitle: false);
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(find.text('Bookmarks'), findsOneWidget);
    expect(appBar.centerTitle, isFalse);
  });
}
