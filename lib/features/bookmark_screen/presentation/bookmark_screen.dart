import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/mushaf/screens/mushaf_reader_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  bool _isMushafBookmark(AyahBookmarkModel bookmark) {
    return bookmark.navigationTarget == BookmarkNavigationTarget.mushaf;
  }

  IconData _bookmarkIcon(AyahBookmarkModel bookmark) {
    return _isMushafBookmark(bookmark)
        ? Icons.menu_book_rounded
        : Icons.book_outlined;
  }

  String _bookmarkChipLabel(AyahBookmarkModel bookmark) {
    return _isMushafBookmark(bookmark) ? 'Mushaf' : 'Quran Block';
  }

  String _bookmarkTitle(AyahBookmarkModel bookmark) {
    return bookmark.surahName ?? 'Surah ${bookmark.surahNumber}';
  }

  String _bookmarkDetails(AyahBookmarkModel bookmark) {
    return 'Surah: ${bookmark.surahNumber}, Ayah: ${bookmark.ayahId}';
  }

  String? _bookmarkBody(AyahBookmarkModel bookmark) {
    final label = bookmark.label?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    if (_isMushafBookmark(bookmark)) {
      final ayaText = bookmark.ayaText?.trim();
      if (ayaText != null && ayaText.isNotEmpty) {
        return ayaText;
      }
    }
    return null;
  }

  Future<void> _openBookmark(
    BuildContext context,
    AyahBookmarkModel bookmark,
  ) async {
    final nav = Navigator.of(context);
    final surahProv = Provider.of<SurahProvider>(context, listen: false);

    if (_isMushafBookmark(bookmark)) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => MushafReaderScreen(
            initialSurahNo: bookmark.surahNumber,
            initialAyaNo: bookmark.ayahId,
          ),
        ),
      );
      return;
    }

    await surahProv.selectSurahByNumber(bookmark.surahNumber);
    nav.push(
      MaterialPageRoute(
        builder: (_) => SurahScreen(scrollToAyahId: bookmark.ayahId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BaseScreenLayout(
      child: CustomScrollView(
        slivers: [
            Consumer<SurahProvider>(
              builder: (context, value, child) {
                return value.bookmarkedList.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Semantics(
                            label: 'No bookmarks saved',
                            child: const Text("No Bookmark Added"),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(10),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            childCount: value.bookmarkedList.length,
                            (context, index) {
                              final bookmark = value.bookmarkedList[index];
                              final bodyText = _bookmarkBody(bookmark);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Semantics(
                                  button: true,
                                  label:
                                      '${bookmark.surahName ?? 'Surah ${bookmark.surahNumber}'}, Ayah ${bookmark.ayahId}${bookmark.label != null && bookmark.label!.isNotEmpty ? ', ${bookmark.label}' : ''}',
                                  hint: 'Double tap to open, swipe to delete',
                                  child: SettingsScreenCard(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () =>
                                          _openBookmark(context, bookmark),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          14,
                                          8,
                                          14,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 34,
                                                right: 14,
                                              ),
                                              child: Icon(
                                                _bookmarkIcon(bookmark),
                                                color: AppTheme.appIconTheme,
                                                size: 24,
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme
                                                              .appIconTheme
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                999,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          _bookmarkChipLabel(
                                                            bookmark,
                                                          ),
                                                          style: theme
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color: AppTheme
                                                                    .appIconTheme,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                letterSpacing:
                                                                    0.2,
                                                              ),
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Semantics(
                                                        button: true,
                                                        label:
                                                            'Remove bookmark for Ayah ${bookmark.ayahId}',
                                                        child: IconButton(
                                                          onPressed: () {
                                                            Provider.of<
                                                                  SurahProvider
                                                                >(
                                                                  context,
                                                                  listen: false,
                                                                )
                                                                .onBookMarkRemoveByIndex(
                                                                  index,
                                                                );
                                                          },
                                                          icon: const Icon(
                                                            Icons
                                                                .delete_outline,
                                                            color: AppTheme
                                                                .appThemePrimary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    _bookmarkTitle(bookmark),
                                                    softWrap: true,
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                  if (bodyText != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      bodyText,
                                                      softWrap: true,
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface,
                                                          ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    _bookmarkDetails(bookmark),
                                                    softWrap: true,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          fontSize: 12,
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
              },
            ),
          ],
        ),
    );
  }
}
