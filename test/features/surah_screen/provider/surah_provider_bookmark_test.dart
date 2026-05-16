import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class _BookmarkTestSurahProvider extends SurahProvider {
  @override
  Future<void> loadBookmarks() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SurahProvider bookmark behavior', () {
    late _BookmarkTestSurahProvider provider;

    setUp(() {
      provider = _BookmarkTestSurahProvider();
      provider.bookmarkedList.clear();
    });

    tearDown(() {
      provider.dispose();
    });

    test('detects same-surah conflicts only within the same section', () {
      provider.bookmarkedList.addAll([
        AyahBookmarkModel(
          surahNumber: 1,
          ayahId: 2,
          surahName: 'Al-Fatihah',
          navigationTarget: BookmarkNavigationTarget.surah,
        ),
        AyahBookmarkModel(
          surahNumber: 1,
          ayahId: 4,
          surahName: 'Al-Fatihah',
          navigationTarget: BookmarkNavigationTarget.mushaf,
        ),
      ]);

      expect(
        provider.hasSurahBookmarkConflict(
          1,
          5,
          navigationTarget: BookmarkNavigationTarget.surah,
        ),
        isTrue,
      );
      expect(
        provider.hasSurahBookmarkConflict(
          1,
          5,
          navigationTarget: BookmarkNavigationTarget.mushaf,
        ),
        isTrue,
      );
      expect(
        provider.hasSurahBookmarkConflict(
          1,
          2,
          navigationTarget: BookmarkNavigationTarget.surah,
        ),
        isFalse,
      );
      expect(
        provider.hasSurahBookmarkConflict(
          1,
          4,
          navigationTarget: BookmarkNavigationTarget.surah,
        ),
        isTrue,
      );
      expect(
        provider.hasSurahBookmarkConflict(
          2,
          1,
          navigationTarget: BookmarkNavigationTarget.surah,
        ),
        isFalse,
      );
    });

    test(
      'keep both preserves existing same-surah bookmarks in a section',
      () async {
        provider.bookmarkedList.add(
          AyahBookmarkModel(
            surahNumber: 1,
            ayahId: 2,
            surahName: 'Al-Fatihah',
            navigationTarget: BookmarkNavigationTarget.surah,
          ),
        );

        final didAdd = await provider.onBookMarkAdd(
          1,
          5,
          surahName: 'Al-Fatihah',
          navigationTarget: BookmarkNavigationTarget.surah,
        );

        expect(didAdd, isTrue);
        expect(
          provider
              .getBookmarksForSurah(
                1,
                navigationTarget: BookmarkNavigationTarget.surah,
              )
              .map((bookmark) => bookmark.ayahId),
          orderedEquals([5, 2]),
        );
      },
    );

    test(
      'replace removes all same-surah conflicts in the same section only',
      () async {
        provider.bookmarkedList.addAll([
          AyahBookmarkModel(
            surahNumber: 1,
            ayahId: 2,
            surahName: 'Al-Fatihah',
            navigationTarget: BookmarkNavigationTarget.surah,
          ),
          AyahBookmarkModel(
            surahNumber: 1,
            ayahId: 7,
            surahName: 'Al-Fatihah',
            navigationTarget: BookmarkNavigationTarget.surah,
          ),
          AyahBookmarkModel(
            surahNumber: 1,
            ayahId: 3,
            surahName: 'Al-Fatihah',
            navigationTarget: BookmarkNavigationTarget.mushaf,
          ),
        ]);

        final didAdd = await provider.onBookMarkAdd(
          1,
          5,
          surahName: 'Al-Fatihah',
          navigationTarget: BookmarkNavigationTarget.surah,
          replaceSameSurah: true,
        );

        expect(didAdd, isTrue);
        expect(
          provider
              .getBookmarksForSurah(
                1,
                navigationTarget: BookmarkNavigationTarget.surah,
              )
              .map((bookmark) => bookmark.ayahId),
          orderedEquals([5]),
        );
        expect(
          provider
              .getBookmarksForSurah(
                1,
                navigationTarget: BookmarkNavigationTarget.mushaf,
              )
              .map((bookmark) => bookmark.ayahId),
          orderedEquals([3]),
        );
      },
    );

    test(
      'same ayah can exist in both sections and stay independently editable',
      () async {
        await provider.onBookMarkAdd(
          1,
          2,
          surahName: 'Al-Fatihah',
          navigationTarget: BookmarkNavigationTarget.surah,
        );
        await provider.onBookMarkAdd(
          1,
          2,
          surahName: 'Al-Fatihah',
          navigationTarget: BookmarkNavigationTarget.mushaf,
        );

        await provider.updateBookmarkLabel(
          1,
          2,
          'Mushaf note',
          navigationTarget: BookmarkNavigationTarget.mushaf,
        );

        expect(
          provider.getBookmark(
            1,
            2,
            navigationTarget: BookmarkNavigationTarget.surah,
          ),
          isNotNull,
        );
        expect(
          provider
              .getBookmark(
                1,
                2,
                navigationTarget: BookmarkNavigationTarget.surah,
              )
              ?.label,
          isNull,
        );
        expect(
          provider
              .getBookmark(
                1,
                2,
                navigationTarget: BookmarkNavigationTarget.mushaf,
              )
              ?.label,
          'Mushaf note',
        );

        await provider.onBookMarkRemoveByAyah(
          1,
          2,
          navigationTarget: BookmarkNavigationTarget.surah,
        );

        expect(
          provider.getBookmark(
            1,
            2,
            navigationTarget: BookmarkNavigationTarget.surah,
          ),
          isNull,
        );
        expect(
          provider.getBookmark(
            1,
            2,
            navigationTarget: BookmarkNavigationTarget.mushaf,
          ),
          isNotNull,
        );
      },
    );
  });
}
