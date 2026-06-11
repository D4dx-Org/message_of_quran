import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/mushaf/screens/mushaf_reader_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  static const Object _clearBookmarkLabelAction = Object();
  static const double _bookmarkIconSize = 24;

  bool _isMushafBookmark(AyahBookmarkModel bookmark) {
    return bookmark.navigationTarget == BookmarkNavigationTarget.mushaf;
  }

  Widget _buildBookmarkIcon(Color color) {
    return Icon(
      Icons.bookmark,
      size: _bookmarkIconSize,
      color: color,
    );
  }

  String _bookmarkChipLabel(AyahBookmarkModel bookmark) {
    return _isMushafBookmark(bookmark) ? "Mus'haf Block" : 'Quran Block';
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

  void _openBookmark(BuildContext context, AyahBookmarkModel bookmark) {
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

    final idx = surahProv.surahList.indexWhere(
      (s) => s.surahNumber == bookmark.surahNumber,
    );
    if (idx < 0) return;
    surahProv.assignIndex(idx);
    nav.push(
      MaterialPageRoute(
        builder: (_) => SurahScreen(scrollToAyahId: bookmark.ayahId),
      ),
    );
  }

  Future<void> _showEditLabelDialog(
    BuildContext context,
    AyahBookmarkModel bookmark,
  ) async {
    final surahProvider = Provider.of<SurahProvider>(context, listen: false);

    final result = await showDialog<Object?>(
      context: context,
      builder: (_) =>
          _BookmarkLabelDialog(initialLabel: bookmark.label?.trim()),
    );

    if (result == null) return;

    final label = identical(result, _clearBookmarkLabelAction)
        ? null
        : (result as String).trim();

    await surahProvider.updateBookmarkLabel(
      bookmark.surahNumber,
      bookmark.ayahId,
      label == null || label.isEmpty ? null : label,
      navigationTarget: bookmark.navigationTarget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = appBarAccentColor(context);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : accentColor;
    final deleteAccentColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.appThemePrimary;

    return BaseScreenLayout(
      contentCardBoxShadows: const [],
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
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(childCount: value.bookmarkedList.length, (
                          context,
                          index,
                        ) {
                          final bookmark = value.bookmarkedList[index];
                          final bodyText = _bookmarkBody(bookmark);
                          return Padding(
                            key: ValueKey('bookmark_${bookmark.surahNumber}_${bookmark.ayahId}'),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Semantics(
                              button: true,
                              label:
                                  '${bookmark.surahName ?? 'Surah ${bookmark.surahNumber}'}, Ayah ${bookmark.ayahId}${bookmark.label != null && bookmark.label!.isNotEmpty ? ', ${bookmark.label}' : ''}',
                              hint:
                                  'Double tap to open. Use the action buttons to edit or delete.',
                              child: SettingsScreenCard(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _openBookmark(context, bookmark),
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
                                          child: _buildBookmarkIcon(
                                            iconColor,
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          appBarAccentFillColor(
                                                            context,
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
                                                            color: accentColor,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            letterSpacing: 0.2,
                                                          ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Semantics(
                                                        button: true,
                                                        label:
                                                            'Edit label for Ayah ${bookmark.ayahId}',
                                                        child: IconButton(
                                                          tooltip: 'Edit label',
                                                          onPressed: () =>
                                                              _showEditLabelDialog(
                                                                context,
                                                                bookmark,
                                                              ),
                                                          icon: Icon(
                                                            Icons.edit_outlined,
                                                            color: iconColor,
                                                          ),
                                                        ),
                                                      ),
                                                      Semantics(
                                                        button: true,
                                                        label:
                                                            'Remove bookmark for Ayah ${bookmark.ayahId}',
                                                        child: IconButton(
                                                          tooltip:
                                                              'Delete bookmark',
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
                                                          icon: Icon(
                                                            Icons
                                                                .delete_outline,
                                                            color:
                                                                deleteAccentColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
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
                                                style: theme.textTheme.bodySmall
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
                        }),
                      ),
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _BookmarkLabelDialog extends StatefulWidget {
  const _BookmarkLabelDialog({this.initialLabel});

  final String? initialLabel;

  @override
  State<_BookmarkLabelDialog> createState() => _BookmarkLabelDialogState();
}

class _BookmarkLabelDialogState extends State<_BookmarkLabelDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit bookmark label'),
      content: TextField(
        controller: _textController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Enter a label',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(BookmarkScreen._clearBookmarkLabelAction),
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_textController.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
