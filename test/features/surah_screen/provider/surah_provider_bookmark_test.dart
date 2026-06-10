import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class _BookmarkTestSurahProvider extends SurahProvider {
  @override
  Future<void> loadBookmarks() async {}
}

SurahModel _buildSurah({
  int surahNumber = 1,
  String name = 'Al-Fatihah',
}) {
  return SurahModel(
    id: '$surahNumber',
    surahNumber: surahNumber,
    name: name,
    searchName: name.toLowerCase(),
    arabicName: 'الفاتحة',
    description: 'The Opening',
    ayathCount: 7,
    place: 'Makkah',
    createdBy: '',
    createdByRole: '',
    isVerified: true,
  );
}

ArabicBlockModel _buildArabicBlock({
  required int ayahNumber,
  required String text,
  int surahNumber = 1,
}) {
  return ArabicBlockModel(
    arabicText: text,
    verseFrom: ayahNumber,
    verseTo: ayahNumber,
    chapterNo: surahNumber,
  );
}

TranslationBlockModel _buildTranslationBlock({
  required String text,
  required int verseFrom,
  int? verseTo,
  int surahNumber = 1,
}) {
  return TranslationBlockModel(
    translationText: text,
    verseFrom: verseFrom,
    verseTo: verseTo ?? verseFrom,
    chapterNo: surahNumber,
  );
}

void _seedCopyFixture(
  _BookmarkTestSurahProvider provider, {
  required List<int> selectedAyahs,
  required List<ArabicBlockModel> arabicBlocks,
  required List<TranslationBlockModel> translationBlocks,
  int surahNumber = 1,
  String surahName = 'Al-Fatihah',
}) {
  provider.surahList = [
    _buildSurah(surahNumber: surahNumber, name: surahName),
  ];
  provider.index = 0;
  provider.arabicBlockList = arabicBlocks;
  provider.translationBlockList = translationBlocks;

  for (final ayah in selectedAyahs) {
    provider.toggleSelection(ayah);
  }
}

String _expectedCopyFooter() {
  final iOSLine = AppConstants.iosStoreUrl.isEmpty
      ? 'iOS :'
      : 'iOS : ${AppConstants.iosStoreUrl}';
  return 'Source : ${AppConstants.appName}\n'
      'Android : ${AppConstants.androidStoreUrl}\n'
    '$iOSLine\n'
      'powered by : D4DX Innovations';
}

String _rtlExportText(String text) => '\u200F\u202B$text\u202C\u200F';

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

  group('SurahProvider selected ayah copy', () {
    late _BookmarkTestSurahProvider provider;

    setUp(() {
      provider = _BookmarkTestSurahProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('includes the selected ayah translation under the Arabic text', () {
      _seedCopyFixture(
        provider,
        selectedAyahs: [1],
        arabicBlocks: [
          _buildArabicBlock(
            ayahNumber: 1,
            text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ﴿١﴾',
          ),
        ],
        translationBlocks: [
          _buildTranslationBlock(
            verseFrom: 1,
            text: 'In the name of God, The Most Gracious, The Dispenser of Grace.',
          ),
        ],
      );

      expect(
        provider.getSelectedText(),
        'Al-Fatihah\n\n'
        'Ayah 1\n'
        '${_rtlExportText('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ﴿١﴾')}\n\n'
        'In the name of God, The Most Gracious, The Dispenser of Grace.\n\n'
        '${_expectedCopyFooter()}',
      );
      expect(provider.getAyahText(1), provider.getSelectedText());
    });

    test('preserves selected ayah order and spacing for multi-ayah copy', () {
      _seedCopyFixture(
        provider,
        selectedAyahs: [2, 1],
        arabicBlocks: [
          _buildArabicBlock(ayahNumber: 1, text: 'First Arabic﴿١﴾'),
          _buildArabicBlock(ayahNumber: 2, text: 'Second Arabic﴿٢﴾'),
        ],
        translationBlocks: [
          _buildTranslationBlock(verseFrom: 1, text: 'First translation.'),
          _buildTranslationBlock(verseFrom: 2, text: 'Second translation.'),
        ],
      );

      expect(
        provider.getSelectedText(),
        'Al-Fatihah\n\n'
        'Ayah 1\n'
        'First Arabic﴿١﴾\n\n'
        'First translation.\n\n'
        'Ayah 2\n'
        'Second Arabic﴿٢﴾\n\n'
        'Second translation.\n\n'
        '${_expectedCopyFooter()}',
      );
    });

    test('falls back to ranged legacy translations when direct verse rows are absent', () {
      _seedCopyFixture(
        provider,
        selectedAyahs: [2],
        arabicBlocks: [
          _buildArabicBlock(ayahNumber: 2, text: 'Legacy Arabic﴿٢﴾'),
        ],
        translationBlocks: [
          _buildTranslationBlock(
            verseFrom: 1,
            verseTo: 2,
            text: '1-2 First legacy sentence. Second legacy sentence.',
          ),
        ],
      );

      final copiedText = provider.getSelectedText();

      expect(copiedText, contains('Ayah 2\nLegacy Arabic﴿٢﴾\n\nSecond legacy sentence.'));
      expect(copiedText, isNot(contains('First legacy sentence.\n\nSource')));
      expect(copiedText, contains('powered by : D4DX Innovations'));
    });
  });
}
