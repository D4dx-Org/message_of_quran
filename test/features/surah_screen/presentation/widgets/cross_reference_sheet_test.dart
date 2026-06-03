import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/utils/cross_reference_parser.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/cross_reference_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpReferenceHost(
    WidgetTester tester, {
    required CrossReference reference,
    String languageCode = LanguageProvider.english,
    bool showTranslation = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'app_language': languageCode,
      'show_translation': showTranslation,
    });
    final languageProvider = LanguageProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
          ChangeNotifierProvider(create: (_) => FontSizeChangerProvider()),
          ChangeNotifierProvider(create: (_) => PlaySettingsProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: TextButton(
                    onPressed: () => CrossReferenceSheet.showParsedReference(
                      context,
                      reference,
                    ),
                    child: const Text('Open reference'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    if (languageProvider.currentLanguage != languageCode) {
      await languageProvider.setLanguage(languageCode);
      await tester.pumpAndSettle();
    }
  }

  Future<void> pumpCrossReferenceSheet(
    WidgetTester tester, {
    required int surahNumber,
    required int ayahNumber,
    int? noteNumber,
    String languageCode = LanguageProvider.english,
    bool showTranslation = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'app_language': languageCode,
      'show_translation': showTranslation,
    });
    final languageProvider = LanguageProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
          ChangeNotifierProvider(create: (_) => FontSizeChangerProvider()),
          ChangeNotifierProvider(create: (_) => PlaySettingsProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CrossReferenceSheet(
              surahNumber: surahNumber,
              ayahNumber: ayahNumber,
              noteNumber: noteNumber,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    if (languageProvider.currentLanguage != languageCode) {
      await languageProvider.setLanguage(languageCode);
      await tester.pumpAndSettle();
    }
  }

  Future<void> pumpInterpretationHeader(
    WidgetTester tester, {
    required InterpretationSheetSurahHeaderText surahHeader,
    required String metadataLabel,
    ThemeData? theme,
    VoidCallback? onClose,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20),
    EdgeInsetsGeometry closeButtonPadding = const EdgeInsets.only(right: 20),
    Offset closeButtonOffset = Offset.zero,
    double titleSpacing = 2,
    bool compactCloseButton = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: Scaffold(
          body: InterpretationSheetHeader(
            surahHeader: surahHeader,
            metadataLabel: metadataLabel,
            onClose: onClose,
            padding: padding,
            closeButtonPadding: closeButtonPadding,
            closeButtonOffset: closeButtonOffset,
            titleSpacing: titleSpacing,
            compactCloseButton: compactCloseButton,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('interpretation header shows meaning on separate subtitle line', (
    tester,
  ) async {
    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: "Al-A'raf",
        subtitle: 'The Faculty Of Discernment',
      ),
      metadataLabel: 'Surah 7 • Interpretation 5 • Verse 5',
    );

    expect(find.text("Al-A'raf"), findsOneWidget);
    expect(find.text('The Faculty Of Discernment'), findsOneWidget);
    expect(
      find.text("Al-A'raf (The Faculty Of Discernment)"),
      findsNothing,
    );

    final subtitle = tester.widget<Text>(
      find.text('The Faculty Of Discernment'),
    );
    expect(subtitle.style?.fontSize, 13);
    expect(subtitle.style?.fontWeight, FontWeight.w500);
    expect(subtitle.style?.color, Colors.grey[700]);

    final metadata = tester.widget<Text>(
      find.text('Surah 7 • Interpretation 5 • Verse 5'),
    );
    expect(metadata.style?.color, Colors.grey[600]);
  });

  testWidgets('interpretation header omits subtitle when missing', (
    tester,
  ) async {
    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: 'Al-Fatihah',
      ),
      metadataLabel: 'Surah 1 • Interpretation 1 • Verse 1',
    );

    expect(find.text('Al-Fatihah'), findsOneWidget);
    expect(find.text('The Opening'), findsNothing);
    expect(
      find.text('Surah 1 • Interpretation 1 • Verse 1'),
      findsOneWidget,
    );
  });

  testWidgets('interpretation header can render subtitle tightly under title', (
    tester,
  ) async {
    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: 'Al-Fatihah',
        subtitle: 'The Opening',
      ),
      metadataLabel: 'Surah 1 • Interpretation 1 • Verse 1',
      titleSpacing: 0,
    );

    final titleRect = tester.getRect(find.text('Al-Fatihah'));
    final subtitleRect = tester.getRect(find.text('The Opening'));

    expect(subtitleRect.top, moreOrLessEquals(titleRect.bottom, epsilon: 0.1));
  });

  testWidgets('interpretation header supports extra bottom gap with compact close button', (
    tester,
  ) async {
    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: 'Al-Fatihah',
        subtitle: 'The Opening',
      ),
      metadataLabel: 'Surah 1 • Interpretation 1 • Verse 1',
      onClose: () {},
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      compactCloseButton: true,
      titleSpacing: 0,
    );

    final iconButton = tester.widget<IconButton>(find.byType(IconButton));

    expect(iconButton.padding, EdgeInsets.zero);
    expect(
      iconButton.constraints,
      const BoxConstraints.tightFor(width: 24, height: 24),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.fromLTRB(20, 0, 20, 8),
      ),
      findsOneWidget,
    );
  });

  testWidgets('interpretation header uses readable dark theme subtitle and metadata colors', (
    tester,
  ) async {
    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: 'Al-Fatihah',
        subtitle: 'The Opening',
      ),
      metadataLabel: 'Surah 1 • Interpretation 1 • Verse 1',
      theme: ThemeData.dark(),
    );

    final subtitle = tester.widget<Text>(find.text('The Opening'));
    final metadata = tester.widget<Text>(
      find.text('Surah 1 • Interpretation 1 • Verse 1'),
    );

    expect(subtitle.style?.color, Colors.white70);
    expect(metadata.style?.color, Colors.white60);
  });

  testWidgets('interpretation header supports compact close button layout', (
    tester,
  ) async {
    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: 'Al-Fatihah',
        subtitle: 'The Opening',
      ),
      metadataLabel: 'Surah 1 • Interpretation 1 • Verse 1',
      onClose: () {},
      padding: const EdgeInsets.fromLTRB(20, 2, 8, 2),
      closeButtonPadding: const EdgeInsets.only(right: 8),
      compactCloseButton: true,
    );

    final iconButton = tester.widget<IconButton>(find.byType(IconButton));

    expect(iconButton.padding, EdgeInsets.zero);
    expect(
      iconButton.constraints,
      const BoxConstraints.tightFor(width: 24, height: 24),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.only(right: 8),
      ),
      findsOneWidget,
    );

    final closeTop = tester.getTopLeft(find.byType(IconButton)).dy;
    final titleTop = tester.getTopLeft(find.text('Al-Fatihah')).dy;
    expect(closeTop, lessThanOrEqualTo(titleTop));
  });

  testWidgets('interpretation header can nudge close button upward', (
    tester,
  ) async {
    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: 'Al-Fatihah',
        subtitle: 'The Opening',
      ),
      metadataLabel: 'Surah 1 • Interpretation 1 • Verse 1',
      onClose: () {},
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
      compactCloseButton: true,
      titleSpacing: 0,
    );

    final defaultCloseTop = tester.getTopLeft(find.byType(IconButton)).dy;

    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: 'Al-Fatihah',
        subtitle: 'The Opening',
      ),
      metadataLabel: 'Surah 1 • Interpretation 1 • Verse 1',
      onClose: () {},
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
      closeButtonOffset: const Offset(0, -4),
      compactCloseButton: true,
      titleSpacing: 0,
    );

    final adjustedCloseTop = tester.getTopLeft(find.byType(IconButton)).dy;
    final titleTop = tester.getTopLeft(find.text('Al-Fatihah')).dy;
    final iconButton = tester.widget<IconButton>(find.byType(IconButton));

    expect(adjustedCloseTop, moreOrLessEquals(defaultCloseTop - 4, epsilon: 0.1));
    expect(adjustedCloseTop, lessThanOrEqualTo(titleTop));
    expect(
      iconButton.constraints,
      const BoxConstraints.tightFor(width: 24, height: 24),
    );
  });

  testWidgets('interpretation header title uses compact line height', (
    tester,
  ) async {
    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: 'Al-Fatihah',
        subtitle: 'The Opening',
      ),
      metadataLabel: 'Surah 1 • Interpretation 1 • Verse 1',
      onClose: () {},
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
      closeButtonOffset: const Offset(0, -4),
      compactCloseButton: true,
      titleSpacing: 0,
    );

    final title = tester.widget<Text>(find.text('Al-Fatihah'));
    expect(title.style?.height, 1.0);
  });

  testWidgets('ayah reference sheet uses compact top action controls', (
    tester,
  ) async {
    await pumpCrossReferenceSheet(
      tester,
      surahNumber: 2,
      ayahNumber: 255,
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.only(top: 8, bottom: 2),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.fromLTRB(20, 0, 12, 8),
      ),
      findsOneWidget,
    );

    final actionButtons = tester.widgetList<IconButton>(find.byType(IconButton));
    expect(actionButtons, hasLength(3));
    for (final button in actionButtons) {
      expect(button.padding, EdgeInsets.zero);
      expect(
        button.constraints,
        const BoxConstraints.tightFor(width: 24, height: 24),
      );
      expect(button.visualDensity, VisualDensity.compact);
      expect(button.splashRadius, 18);
    }

    final upwardOffsets = find.byWidgetPredicate(
      (widget) =>
          widget is Transform && widget.transform.storage[13] == -10.0,
    );
    expect(upwardOffsets, findsNWidgets(3));
  });

  testWidgets('note-only reference opens explanation sheet', (tester) async {
    await pumpReferenceHost(
      tester,
      reference: const CrossReference(
        matchedText: 'surah 2, note 247',
        surahNumber: 2,
        noteNumber: 247,
      ),
    );

    await tester.tap(find.text('Open reference'));
    await tester.pumpAndSettle();

    expect(find.text('Explanation'), findsNothing);
    expect(find.text('Surah 2 • Interpretation 247'), findsOneWidget);
    expect(find.text('Verse Range 1'), findsNothing);
    expect(find.text('No explanation found'), findsOneWidget);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.only(top: 8, bottom: 2),
      ),
      findsOneWidget,
    );

    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(iconButton.padding, EdgeInsets.zero);
    expect(
      iconButton.constraints,
      const BoxConstraints.tightFor(width: 24, height: 24),
    );
  });

  testWidgets('ayah reference opens verse sheet', (tester) async {
    await pumpReferenceHost(
      tester,
      reference: const CrossReference(
        matchedText: '2:255',
        surahNumber: 2,
        ayahNumber: 255,
      ),
    );

    await tester.tap(find.text('Open reference'));
    await tester.pumpAndSettle();

    expect(find.text('Verse not found'), findsOneWidget);
    expect(find.text('Explanation'), findsNothing);
  });
}
