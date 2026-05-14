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
  }

  String? lastUpdatedLabel;

  @override
  Future<void> loadBookmarks() async {}

  @override
  Future<void> updateBookmarkLabel(
    int surahNumber,
    int ayahId,
    String? label,
  ) async {
    lastUpdatedLabel = label;
    final bookmarkIndex = bookmarkedList.indexWhere(
      (bookmark) =>
          bookmark.surahNumber == surahNumber && bookmark.ayahId == ayahId,
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

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Study later');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(provider.lastUpdatedLabel, 'Study later');
    expect(find.text('Study later'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}