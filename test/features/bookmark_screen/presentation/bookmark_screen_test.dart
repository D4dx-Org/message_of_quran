import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/features/bookmark_screen/presentation/bookmark_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class _TestSurahProvider extends SurahProvider {
  _TestSurahProvider() {
    bookmarkedList.add(
      AyahBookmarkModel(
        surahNumber: 2,
        ayahId: 255,
        surahName: 'Al-Baqarah',
        label: 'Old label',
        navigationTarget: BookmarkNavigationTarget.surah,
      ),
    );
    bookmarkedList.add(
      AyahBookmarkModel(
        surahNumber: 108,
        ayahId: 1,
        surahName: 'Al-Kawthar',
        ayaText: 'Indeed, We have granted you abundance.',
        navigationTarget: BookmarkNavigationTarget.mushaf,
      ),
    );
    bookmarkedList.add(
      AyahBookmarkModel(
        surahNumber: 2,
        ayahId: 255,
        surahName: 'Al-Baqarah',
        pageNumber: 42,
        navigationTarget: BookmarkNavigationTarget.mushafPage,
      ),
    );
  }

  String? lastUpdatedLabel;
  String? lastUpdatedNavigationTarget;
  int? lastUpdatedPageNumber;

  @override
  Future<void> loadBookmarks() async {}

  @override
  Future<void> updateBookmarkLabel(
    int surahNumber,
    int ayahId,
    String? label, {
    String navigationTarget = BookmarkNavigationTarget.surah,
    int? pageNumber,
  }) async {
    lastUpdatedLabel = label;
    lastUpdatedNavigationTarget = navigationTarget;
    lastUpdatedPageNumber = pageNumber;
    final bookmarkIndex = bookmarkedList.indexWhere(
      (bookmark) =>
          bookmark.surahNumber == surahNumber &&
          bookmark.ayahId == ayahId &&
          bookmark.navigationTarget == navigationTarget &&
          bookmark.pageNumber == pageNumber,
    );
    if (bookmarkIndex < 0) return;

    final previousBookmark = bookmarkedList[bookmarkIndex];
    bookmarkedList[bookmarkIndex] = AyahBookmarkModel(
      surahNumber: previousBookmark.surahNumber,
      ayahId: previousBookmark.ayahId,
      surahName: previousBookmark.surahName,
      ayaText: previousBookmark.ayaText,
      surahArabicName: previousBookmark.surahArabicName,
      surahArabicNumber: previousBookmark.surahArabicNumber,
      label: label,
      navigationTarget: previousBookmark.navigationTarget,
      pageNumber: previousBookmark.pageNumber,
    );
    notifyListeners();
  }
}

void main() {
  testWidgets('saves bookmark labels after the dialog closes', (
    WidgetTester tester,
  ) async {
    final provider = _TestSurahProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SurahProvider>.value(
        value: provider,
        child: const MaterialApp(home: BookmarkScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Study later');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(provider.lastUpdatedLabel, 'Study later');
    expect(
      provider.lastUpdatedNavigationTarget,
      BookmarkNavigationTarget.surah,
    );
    expect(find.text('Study later'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('passes the bookmark section when editing a mushaf label', (
    WidgetTester tester,
  ) async {
    final provider = _TestSurahProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SurahProvider>.value(
        value: provider,
        child: const MaterialApp(home: BookmarkScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).at(1));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Mushaf note');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(provider.lastUpdatedLabel, 'Mushaf note');
    expect(
      provider.lastUpdatedNavigationTarget,
      BookmarkNavigationTarget.mushaf,
    );
    expect(provider.lastUpdatedPageNumber, isNull);
    expect(find.text('Mushaf note'), findsOneWidget);
  });

  testWidgets('renders distinct mushaf page bookmark details', (
    WidgetTester tester,
  ) async {
    final provider = _TestSurahProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SurahProvider>.value(
        value: provider,
        child: const MaterialApp(home: BookmarkScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Mus'haf Page"), findsOneWidget);
    expect(find.text('Page 42'), findsNothing);
    expect(find.text('Page: 42'), findsNothing);
    expect(find.text('Surah: 2, Page: 42'), findsOneWidget);
    expect(find.text('Page: 42, Surah: 2, Ayah: 255'), findsNothing);
    expect(find.text('Al-Baqarah'), findsNWidgets(2));
  });

  testWidgets('passes page identity when editing a mushaf page label', (
    WidgetTester tester,
  ) async {
    final provider = _TestSurahProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SurahProvider>.value(
        value: provider,
        child: const MaterialApp(home: BookmarkScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Resume here');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      provider.lastUpdatedNavigationTarget,
      BookmarkNavigationTarget.mushafPage,
    );
    expect(provider.lastUpdatedPageNumber, 42);
    expect(find.text('Resume here'), findsOneWidget);
  });

  testWidgets('renders the navbar bookmark icon for all bookmark tiles', (
    WidgetTester tester,
  ) async {
    final provider = _TestSurahProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SurahProvider>.value(
        value: provider,
        child: const MaterialApp(home: BookmarkScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byIcon(Icons.bookmark),
      findsNWidgets(provider.bookmarkedList.length),
    );
    expect(find.byIcon(Icons.book_outlined), findsNothing);
    expect(find.byIcon(Icons.menu_book_rounded), findsNothing);
  });
}
