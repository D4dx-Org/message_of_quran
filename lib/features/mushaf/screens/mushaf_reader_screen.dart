import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/core/services/audio_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_message_of_the_quran/features/bookmark_screen/presentation/bookmark_conflict_dialog.dart';

import '../../../core/utils/responsive_helper.dart';
import '../provider/mushaf_reader_provider.dart';
import '../services/mushaf_download_manager.dart';
import '../../../core/widgets/base_screen_layout.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings_screen/presentation/reader_settings_screen.dart';
import '../../surah_screen/provider/surah_provider.dart';
import '../models/page_meta.dart';
import '../widgets/mushaf_download_required_dialog.dart';
import '../widgets/mushaf_page_view.dart';
import '../../tajweed/presentation/widgets/tajweed_page_view.dart';
import '../../settings_screen/providers/tajweed_provider.dart';

const _kPrimaryColor = AppTheme.appIconTheme;
const _kSecondaryDark = AppTheme.appIconTheme;
const _kNeutral500 = Color(0xFF525866);
const _kDefaultFontSize = 24.0;

class _MushafReaderAnchor {
  const _MushafReaderAnchor({
    required this.page,
    required this.isListView,
    this.listOffset,
  });

  final int page;
  final bool isListView;
  final double? listOffset;
}

/// Full-screen Mushaf reader with an offline 2-page preview.
class MushafReaderScreen extends StatefulWidget {
  const MushafReaderScreen({
    super.key,
    this.initialPage,
    this.initialSurahNo,
    this.initialAyaNo,
  });

  final int? initialPage;
  final int? initialSurahNo;
  final int? initialAyaNo;

  @override
  State<MushafReaderScreen> createState() => _MushafReaderScreenState();
}

class _MushafReaderScreenState extends State<MushafReaderScreen>
    with TickerProviderStateMixin {
  late final MushafReaderProvider _p;
  final MushafDownloadManager _downloadManager = MushafDownloadManager.instance;

  late final AnimationController _barsAnimController;
  late final Animation<Offset> _appBarSlideAnim;
  late final Animation<Offset> _bottomBarSlideAnim;
  bool _barsVisible = false;
  bool _initialSynced = false;

  int? _jumpTargetPage;
  Timer? _jumpClearTimer;

  @override
  void initState() {
    super.initState();
    _barsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _appBarSlideAnim =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _barsAnimController, curve: Curves.easeInOut),
        );
    _bottomBarSlideAnim =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: _barsAnimController, curve: Curves.easeInOut),
        );
    _p = MushafReaderProvider(
      handler: audioHandler!,
      initialPage: widget.initialPage,
      initialSurahNo: widget.initialSurahNo,
      initialAyaNo: widget.initialAyaNo,
    );
    _p.addListener(_onProviderChanged);
    _p.onManualScrollWhilePlaying = _showAutoScrollPrompt;
    _p.init();
    _downloadManager.addListener(_onDownloadStateChanged);
  }

  @override
  void dispose() {
    _downloadManager.removeListener(_onDownloadStateChanged);
    _jumpClearTimer?.cancel();
    _barsAnimController.dispose();
    _p.removeListener(_onProviderChanged);
    _p.dispose();
    super.dispose();
  }

  void _onDownloadStateChanged() {
    if (_downloadManager.isDone && mounted) {
      _p.setFontsInstalled();
    }
  }

  void _onProviderChanged() {
    if (!mounted) return;
    if (_p.initialised && !_initialSynced && _p.allPageMetas.isNotEmpty) {
      _initialSynced = true;
    }

    final scrollPage = _p.consumePendingScrollPage();
    if (scrollPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollListToPage(scrollPage);
        }
      });
    }
  }

  void _showAutoScrollPrompt() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text('Stop auto-scrolling with audio?'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Stop',
              onPressed: () =>
                  _p.resolveScrollConfirmation(stopFollowing: true),
            ),
          ),
        )
        .closed
        .then((_) => _p.resolveScrollConfirmation(stopFollowing: false));
  }

  void _setJumpTarget(int page) {
    _jumpTargetPage = page;
    _jumpClearTimer?.cancel();
    _jumpClearTimer = Timer(const Duration(milliseconds: 700), () {
      _jumpTargetPage = null;
    });
  }

  void _onPageChanged(int index) {
    _p.onPageChanged(index);
    final page = index + 1;

    if (_jumpTargetPage != null) {
      if (page == _jumpTargetPage) {
        _jumpClearTimer?.cancel();
        _jumpTargetPage = null;
      } else {
        return;
      }
    }

    if (!_p.fontsInstalled && page >= MushafReaderProvider.previewLimit) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted &&
            !_p.fontsInstalled &&
            _p.currentPage >= MushafReaderProvider.previewLimit) {
          _showDownloadPrompt(
            targetPage: MushafReaderProvider.previewLimit + 1,
          );
        }
      });
    }
  }

  int _autoNavGen = 0;

  Future<void> _scrollListToPage(int targetPage) async {
    final items = _p.listItems;
    if (items.isEmpty || !_p.listScrollController.hasClients) {
      _p.isAutoNavigating = false;
      return;
    }
    final pageH = _p.listPageHeight;
    if (pageH <= 0) {
      _p.isAutoNavigating = false;
      return;
    }
    final offset = (targetPage - 1) * pageH;
    final gen = ++_autoNavGen;
    _p.isAutoNavigating = true;
    await _p.listScrollController.animateTo(
      offset.clamp(0.0, _p.listScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    if (gen == _autoNavGen) {
      _p.isAutoNavigating = false;
      _p.onListScrollUpdate(_p.listScrollController.offset, pageH);
    }
  }

  void _showDownloadPrompt({required int targetPage}) {
    final dm = _downloadManager;
    if (dm.isDownloading) {
      final percent = (dm.progress * 100).toStringAsFixed(0);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Download in progress \u2014 $percent% complete'),
            duration: const Duration(seconds: 3),
          ),
        );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final maxW = ResponsiveHelper.bottomSheetMaxWidth(ctx);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW ?? double.infinity),
            child: MushafDownloadRequiredDialog(
              onCancel: () => Navigator.of(ctx).pop(),
              onDownload: () {
                Navigator.of(ctx).pop();
                dm.startDownload();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Mus'haf download started. You can continue using the app.",
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
              },
            ),
          ),
        );
      },
    );
  }

  // ─── Aya action row ───────────────────────────────────────────────────────

  Widget _buildAyaActionRow() {
    final suraNo = _p.selectedSuraNo;
    final ayaNo = _p.selectedAyaNo;
    if (suraNo == null || ayaNo == null) return const SizedBox.shrink();
    final surahProvider = context.watch<SurahProvider>();
    final isMushafBookmarked = surahProvider.isAyahBookmarkedForTarget(
      suraNo,
      ayaNo,
      BookmarkNavigationTarget.mushaf,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            icon: _p.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onPressed: () => _p.onPlayPressed(),
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.share_rounded,
            onPressed: () => _shareVerse(suraNo, ayaNo),
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: isMushafBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            onPressed: () => _toggleBookmarkForSelectedAyah(
              suraNo,
              ayaNo,
              isMushafBookmarked,
            ),
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.stop_rounded,
            onPressed: () => _p.stopAndClear(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final scale = ResponsiveHelper.scaleFactor(context);
    return Container(
      width: 36 * scale,
      height: 36 * scale,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18 * scale),
        onPressed: onPressed,
      ),
    );
  }

  void _shareVerse(int suraNo, int ayaNo) async {
    const appName = 'Quran Asad Malayalam';
    final shareText = 'Verse: $suraNo:$ayaNo\n\nShared via $appName';
    try {
      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to share verse')));
      }
    }
  }

  PageMeta? _currentPageMetaSync() {
    if (_p.currentPage <= 0 || _p.currentPage > _p.allPageMetas.length) {
      return null;
    }
    return _p.allPageMetas[_p.currentPage - 1];
  }

  Future<PageMeta?> _currentPageMeta() async {
    final cached = _currentPageMetaSync();
    if (cached != null) return cached;
    return _p.repository.getPageMeta(_p.currentPage);
  }

  _MushafReaderAnchor _captureReaderAnchor() {
    return _MushafReaderAnchor(
      page: _p.currentPage,
      isListView: _p.isListView,
      listOffset: _p.isListView && _p.listScrollController.hasClients
          ? _p.listScrollController.offset
          : null,
    );
  }

  Future<void> _restoreReaderAnchor(_MushafReaderAnchor anchor) async {
    if (!mounted) return;

    if (_p.isListView != anchor.isListView) {
      _p.isAutoNavigating = true;
      _setJumpTarget(anchor.page);
      _p.toggleListView();
      await WidgetsBinding.instance.endOfFrame;
    }

    if (!mounted) return;

    if (anchor.isListView) {
      if (_p.listScrollController.hasClients && anchor.listOffset != null) {
        final position = _p.listScrollController.position;
        final targetOffset = anchor.listOffset!
            .clamp(0.0, position.maxScrollExtent)
            .toDouble();
        if ((_p.listScrollController.offset - targetOffset).abs() > 0.5) {
          _p.isAutoNavigating = true;
          _p.listScrollController.jumpTo(targetOffset);
          _p.onListScrollUpdate(targetOffset, _p.listPageHeight);
        }
      } else {
        _setJumpTarget(anchor.page);
        _p.tryNavigateTo(anchor.page);
      }
      _p.isAutoNavigating = false;
      return;
    }

    final targetIndex = anchor.page - 1;
    if (_p.pageController?.hasClients ?? false) {
      final currentIndex = _p.pageController!.page?.round();
      if (currentIndex != targetIndex) {
        _p.pageController!.jumpToPage(targetIndex);
      } else if (_p.currentPage != anchor.page) {
        _p.onPageChanged(targetIndex);
      }
    } else {
      _setJumpTarget(anchor.page);
      _p.tryNavigateTo(anchor.page);
    }

    _p.isAutoNavigating = false;
  }

  Future<void> _openReaderSettings() async {
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final anchor = _captureReaderAnchor();

    await _p.stopAndClear();
    if (!mounted) return;

    await navigator.push(
      MaterialPageRoute(builder: (_) => const ReaderSettingsScreen()),
    );

    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    await _restoreReaderAnchor(anchor);
  }

  Future<void> _toggleCurrentPageBookmark(bool isBookmarked) async {
    final messenger = ScaffoldMessenger.of(context);
    final surahProvider = context.read<SurahProvider>();
    final pageMeta = await _currentPageMeta();
    if (!mounted || pageMeta == null) return;

    const navigationTarget = BookmarkNavigationTarget.mushafPage;

    if (isBookmarked) {
      await surahProvider.onBookMarkRemoveByAyah(
        pageMeta.suraNo,
        pageMeta.startAya,
        navigationTarget: navigationTarget,
        pageNumber: pageMeta.pageNo,
      );
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Page bookmark removed')));
      return;
    }

    if (surahProvider.surahList.isEmpty) {
      await surahProvider.getAllSurah();
    }
    if (!mounted) return;

    dynamic surah;
    for (final item in surahProvider.surahList) {
      if (item.surahNumber == pageMeta.suraNo) {
        surah = item;
        break;
      }
    }

    final didAdd = await surahProvider.onBookMarkAdd(
      pageMeta.suraNo,
      pageMeta.startAya,
      surahName: surah?.name as String?,
      surahArabicName: surah?.arabicName as String?,
      navigationTarget: navigationTarget,
      pageNumber: pageMeta.pageNo,
    );

    if (!mounted || !didAdd) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Page bookmark added')));
  }

  Future<void> _toggleBookmarkForSelectedAyah(
    int suraNo,
    int ayaNo,
    bool isMushafBookmarked,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final surahProvider = context.read<SurahProvider>();
    const navigationTarget = BookmarkNavigationTarget.mushaf;

    if (isMushafBookmarked) {
      await surahProvider.onBookMarkRemoveByAyah(
        suraNo,
        ayaNo,
        navigationTarget: navigationTarget,
      );
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Bookmark removed')));
      return;
    }

    if (surahProvider.surahList.isEmpty) {
      await surahProvider.getAllSurah();
    }
    if (!mounted) return;
    dynamic surah;
    for (final item in surahProvider.surahList) {
      if (item.surahNumber == suraNo) {
        surah = item;
        break;
      }
    }

    var replaceSameSurah = false;
    if (surahProvider.hasSurahBookmarkConflict(
      suraNo,
      ayaNo,
      navigationTarget: navigationTarget,
    )) {
      final resolution = await showBookmarkConflictDialog(
        context,
        navigationTarget: navigationTarget,
        surahName: surah?.name as String?,
      );
      if (!mounted || resolution == null) return;
      replaceSameSurah = resolution == BookmarkConflictResolution.replace;
    }

    final didAdd = await surahProvider.onBookMarkAdd(
      suraNo,
      ayaNo,
      surahName: surah?.name as String?,
      surahArabicName: surah?.arabicName as String?,
      navigationTarget: navigationTarget,
      replaceSameSurah: replaceSameSurah,
    );

    if (!mounted || !didAdd) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            replaceSameSurah ? 'Bookmark replaced' : 'Bookmark added',
          ),
        ),
      );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _p,
      child: Consumer<MushafReaderProvider>(
        builder: (context, p, _) {
          if (!p.initialised || p.pageController == null) {
            return const BaseScreenLayout(
              contentTopInset: 0,
              topBorderRadius: 0,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildScaffold(context);
        },
      ),
    );
  }

  void _toggleBars() {
    _barsVisible = !_barsVisible;
    if (_barsVisible) {
      _barsAnimController.forward();
    } else {
      _barsAnimController.reverse();
    }
  }

  bool _useDesktopWebReaderLayout(BuildContext context) {
    return kIsWeb;
  }

  int _lastReadablePage() {
    return _p.fontsInstalled
        ? MushafReaderProvider.totalPages
        : MushafReaderProvider.previewLimit;
  }

  void _goToHigherPage() {
    final next = _p.currentPage + 1;
    if (next <= _lastReadablePage()) {
      _p.tryNavigateTo(next);
    }
  }

  void _goToLowerPage() {
    final prev = _p.currentPage - 1;
    if (prev >= 1) {
      _p.tryNavigateTo(prev);
    }
  }

  void _toggleReaderViewMode() {
    final wasListView = _p.isListView;
    final targetPage = _p.currentPage;
    _p.isAutoNavigating = true;
    _setJumpTarget(targetPage);
    _p.toggleListView();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!wasListView) {
        _scrollListToPage(targetPage);
      } else {
        _p.pageController?.jumpToPage(targetPage - 1);
        _p.isAutoNavigating = false;
      }
    });
  }

  double _landscapeFontSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (!isLandscape) return _kDefaultFontSize;
    // Scale proportionally to the wider landscape width.
    final ratio = size.width / size.height;
    return _kDefaultFontSize * ratio;
  }

  Widget _buildReaderViewport(BuildContext context, double fontSize) {
    return _p.isListView
        ? _buildListView()
        : PageView.builder(
            controller: _p.pageController!,
            reverse: true,
            itemCount: _p.fontsInstalled
                ? MushafReaderProvider.totalPages
                : MushafReaderProvider.previewLimit,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final tajweed = context.read<TajweedProvider>();
              if (tajweed.enabled && tajweed.fontsInstalled) {
                return TajweedPageView(
                  pageNo: index + 1,
                  repository: _p.repository,
                  selectedAyaId: _p.selectedAyaId,
                  playingAyaId: _p.audioPlayingAyaId,
                  onAyaTap: _toggleBars,
                  quranFontSize: fontSize,
                );
              }
              return MushafPageView(
                pageNo: index + 1,
                repository: _p.repository,
                selectedAyaId: _p.selectedAyaId,
                playingAyaId: _p.audioPlayingAyaId,
                onAyaTap: _toggleBars,
                onAyaLongPress: _p.onAyaTap,
                onDismissSelection: _p.clearSelection,
                quranFontSize: fontSize,
                actionRow: _p.selectedAyaId != null
                    ? _buildAyaActionRow()
                    : null,
              );
            },
          );
  }

  Widget _buildDesktopReaderToolbar(BuildContext context) {
    final surahProvider = context.watch<SurahProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xff163d6e) : Colors.white;
    final titleColor = isDark ? Colors.white : _kSecondaryDark;
    final subtitleColor = isDark ? Colors.white70 : _kNeutral500;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final totalPages = _lastReadablePage();
    final isCurrentPageBookmarked = surahProvider.isMushafPageBookmarked(
      _p.currentPage,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactToolbar = constraints.maxWidth < 760;

            final titleBlock = Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Mus'haf Reader",
                    style: AppTextTheme.popinsDefault(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Page ${_p.currentPage} of $totalPages • ${_p.isListView ? 'List view' : 'Page view'}',
                    style: AppTextTheme.popinsDefault(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            );

            final playButton = _p.isLoadingAudio
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: _p.isPlaying ? 'Pause audio' : 'Play audio',
                    onPressed: _p.isPlaying || _p.playingLabel != null
                        ? _p.togglePlayPause
                        : _p.onPlayPressed,
                    icon: Icon(
                      _p.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: titleColor,
                    ),
                  );

            final paginationRow = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Higher page number',
                  onPressed: _p.currentPage < totalPages ? _goToHigherPage : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: titleColor,
                ),
                Text(
                  '${_p.currentPage}',
                  style: AppTextTheme.popinsDefault(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Lower page number',
                  onPressed: _p.currentPage > 1 ? _goToLowerPage : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: titleColor,
                ),
              ],
            );

            if (isCompactToolbar) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: titleColor),
                      ),
                      const SizedBox(width: 8),
                      titleBlock,
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      playButton,
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Switch view',
                        onPressed: _toggleReaderViewMode,
                        icon: Icon(
                          _p.isListView
                              ? Icons.view_day_rounded
                              : Icons.view_carousel_rounded,
                          color: titleColor,
                        ),
                      ),
                      IconButton(
                        tooltip: isCurrentPageBookmarked
                            ? 'Remove page bookmark'
                            : 'Bookmark this page',
                        onPressed: () => _toggleCurrentPageBookmark(
                          isCurrentPageBookmarked,
                        ),
                        icon: Icon(
                          isCurrentPageBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: titleColor,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Reader settings',
                        onPressed: _openReaderSettings,
                        icon: Icon(Icons.settings_rounded, color: titleColor),
                      ),
                      const Spacer(),
                      paginationRow,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: titleColor),
                ),
                const SizedBox(width: 8),
                titleBlock,
                playButton,
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Switch view',
                  onPressed: _toggleReaderViewMode,
                  icon: Icon(
                    _p.isListView
                        ? Icons.view_day_rounded
                        : Icons.view_carousel_rounded,
                    color: titleColor,
                  ),
                ),
                IconButton(
                  tooltip: isCurrentPageBookmarked
                      ? 'Remove page bookmark'
                      : 'Bookmark this page',
                  onPressed: () => _toggleCurrentPageBookmark(
                    isCurrentPageBookmarked,
                  ),
                  icon: Icon(
                    isCurrentPageBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: titleColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Reader settings',
                  onPressed: _openReaderSettings,
                  icon: Icon(Icons.settings_rounded, color: titleColor),
                ),
                const SizedBox(width: 12),
                paginationRow,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopReaderScaffold(BuildContext context, double fontSize) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final viewportColor = isDark ? const Color(0xff163d6e) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        children: [
          _buildDesktopReaderToolbar(context),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: viewportColor,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: _buildReaderViewport(context, fontSize),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final fontSize = _landscapeFontSize(context);
    final floatingActionButton =
        (!_p.fontsInstalled &&
            _p.currentPage == MushafReaderProvider.previewLimit)
        ? FloatingActionButton.extended(
            onPressed: () => _showDownloadPrompt(
              targetPage: MushafReaderProvider.previewLimit + 1,
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Continue Reading'),
            backgroundColor: _kPrimaryColor,
            foregroundColor: Colors.white,
          )
        : null;

    if (_useDesktopWebReaderLayout(context)) {
      return BaseScreenLayout(
        contentTopInset: 0,
        topBorderRadius: 0,
        floatingActionButton: floatingActionButton,
        child: _buildDesktopReaderScaffold(context, fontSize),
      );
    }

    return BaseScreenLayout(
      contentTopInset: 0,
      topBorderRadius: 0,
      floatingActionButton: floatingActionButton,
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildReaderViewport(context, fontSize),
          ),
          // Animated AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _appBarSlideAnim,
              child: _buildAppBar(context),
            ),
          ),
          // Animated BottomBar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _bottomBarSlideAnim,
              child: _buildBottomBar(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App bar ──────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    final surahProvider = context.watch<SurahProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xff0c2d52).withValues(alpha: 0.95)
        : AppTheme.appThemePrimary;
    const textColor = Colors.white;
    final isCurrentPageBookmarked = surahProvider.isMushafPageBookmarked(
      _p.currentPage,
    );

    final hPad = ResponsiveHelper.horizontalPadding(context);
    return Container(
      color: bgColor,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: hPad,
        right: hPad,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: textColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quran — Page ${_p.currentPage}',
                style: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _p.isListView
                  ? Icons.view_day_rounded
                  : Icons.view_carousel_rounded,
              color: textColor,
            ),
            onPressed: _toggleReaderViewMode,
          ),
          IconButton(
            icon: Icon(
              isCurrentPageBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: textColor,
            ),
            tooltip: isCurrentPageBookmarked
                ? 'Remove page bookmark'
                : 'Bookmark this page',
            onPressed: () => _toggleCurrentPageBookmark(
              isCurrentPageBookmarked,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            color: textColor,
            tooltip: 'Reader settings',
            onPressed: _openReaderSettings,
          ),
        ],
      ),
    );
  }

  // ─── Bottom bar (audio controls) ─────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xff0c2d52).withValues(alpha: 0.95)
        : AppTheme.appThemePrimary;
    const textColor = Colors.white;
    final scale = ResponsiveHelper.scaleFactor(context);

    Widget navButton({
      required bool enabled,
      required IconData icon,
      required VoidCallback onPressed,
      required String tooltip,
    }) {
      return SizedBox(
        width: 40 * scale,
        height: 40 * scale,
        child: enabled
            ? IconButton(
                tooltip: tooltip,
                icon: Icon(icon),
                color: textColor,
                onPressed: onPressed,
              )
            : null,
      );
    }

    final playButton = _p.isLoadingAudio
        ? const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : GestureDetector(
            onTap: _p.isPlaying || _p.playingLabel != null
                ? _p.togglePlayPause
                : _p.onPlayPressed,
            child: Container(
              width: 40 * scale,
              height: 40 * scale,
              decoration: const BoxDecoration(
                color: _kSecondaryDark,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _p.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28 * scale,
              ),
            ),
          );

    final hPad = ResponsiveHelper.horizontalPadding(context);
    return Container(
      color: bgColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        left: hPad,
        right: hPad,
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: navButton(
                enabled: _p.currentPage < _lastReadablePage(),
                icon: Icons.chevron_left_rounded,
                onPressed: _goToHigherPage,
                tooltip: 'Previous page',
              ),
            ),
          ),
          Expanded(
            child: Center(child: playButton),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '${_p.currentPage} / ${_lastReadablePage()}',
                style: const TextStyle(color: textColor, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: navButton(
                enabled: _p.currentPage > 1,
                icon: Icons.chevron_right_rounded,
                onPressed: _goToLowerPage,
                tooltip: 'Next page',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── List view ────────────────────────────────────────────────────────────

  Widget _buildListView() {
    final visibleItems = _p.getVisibleListItems();
    if (visibleItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_kPrimaryColor),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageH = constraints.maxHeight;
        _p.listPageHeight = pageH;
        return NotificationListener<ScrollUpdateNotification>(
          onNotification: (n) {
            final prevPage = _p.currentPage;
            _p.onListScrollUpdate(n.metrics.pixels, pageH);
            final newPage = _p.currentPage;
            if (newPage != prevPage) {
              if (_jumpTargetPage != null) {
                if (newPage == _jumpTargetPage) {
                  _jumpClearTimer?.cancel();
                  _jumpTargetPage = null;
                }
              }
            }
            return false;
          },
          child: ListView.builder(
            controller: _p.listScrollController,
            physics: const ClampingScrollPhysics(),
            itemCount: visibleItems.length,
            itemBuilder: (ctx, index) {
              final item = visibleItems[index];
              final tajweed2 = context.read<TajweedProvider>();
              if (tajweed2.enabled && tajweed2.fontsInstalled) {
                return SizedBox(
                  height: pageH,
                  child: TajweedPageView(
                    pageNo: (item as MushafListPage).pageNo,
                    repository: _p.repository,
                    selectedAyaId: _p.selectedAyaId,
                    playingAyaId: _p.audioPlayingAyaId,
                    onAyaTap: _toggleBars,
                    quranFontSize: _landscapeFontSize(context),
                  ),
                );
              }
              return SizedBox(
                height: pageH,
                child: MushafPageView(
                  pageNo: (item as MushafListPage).pageNo,
                  repository: _p.repository,
                  selectedAyaId: _p.selectedAyaId,
                  playingAyaId: _p.audioPlayingAyaId,
                  onAyaTap: _toggleBars,
                  onAyaLongPress: _p.onAyaTap,
                  onDismissSelection: _p.clearSelection,
                  quranFontSize: _landscapeFontSize(context),
                  actionRow: _p.selectedAyaId != null
                      ? _buildAyaActionRow()
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
