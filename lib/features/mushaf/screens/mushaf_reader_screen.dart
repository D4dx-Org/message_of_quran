import 'dart:async';

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
import '../../../core/theme/app_theme.dart';
import '../../surah_screen/provider/surah_provider.dart';
import '../widgets/mushaf_page_view.dart';

const _kPrimaryColor = AppTheme.appIconTheme;
const _kSecondaryDark = AppTheme.appIconTheme;
const _kWhite = Color(0xffFFFFFF);
const _kNeutral500 = Color(0xFF525866);
const _kDefaultFontSize = 24.0;

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
      _scrollListToPage(scrollPage);
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
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.download_rounded, color: _kSecondaryDark),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Download Required',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Pages 1\u20132 are available offline.\n'
                'Download the Mushaf font pack to read the full Quran.\n\n'
                'The download will continue in the background.',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14, color: _kNeutral500),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    dm.startDownload();
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mushaf download started. You can continue using the app.',
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kSecondaryDark,
                    foregroundColor: _kWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Download', style: TextStyle(fontSize: 14)),
                ),
              ],
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
    const appName = 'The Message of The Quran';
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

  double _landscapeFontSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (!isLandscape) return _kDefaultFontSize;
    // Scale proportionally to the wider landscape width.
    final ratio = size.width / size.height;
    return _kDefaultFontSize * ratio;
  }

  Widget _buildScaffold(BuildContext context) {
    final fontSize = _landscapeFontSize(context);
    return BaseScreenLayout(
      topBorderRadius: 0,
      floatingActionButton:
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
          : null,
      child: Stack(
        children: [
          Positioned.fill(
            child: _p.isListView
                ? _buildListView()
                : PageView.builder(
                    controller: _p.pageController!,
                    reverse: true,
                    itemCount: _p.fontsInstalled
                        ? MushafReaderProvider.totalPages
                        : MushafReaderProvider.previewLimit,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
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
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.95)
        : AppTheme.appThemePrimary;
    const textColor = Colors.white;

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
            onPressed: () {
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
            },
          ),
        ],
      ),
    );
  }

  // ─── Bottom bar (audio controls) ─────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.95)
        : AppTheme.appThemePrimary;
    const textColor = Colors.white;

    final hPad = ResponsiveHelper.horizontalPadding(context);
    return Container(
      color: bgColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        left: hPad,
        right: hPad,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous page (hidden on last page)
          if (_p.currentPage <
              (_p.fontsInstalled
                  ? MushafReaderProvider.totalPages
                  : MushafReaderProvider.previewLimit))
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              color: textColor,
              onPressed: () {
                final next = _p.currentPage + 1;
                if (next <= MushafReaderProvider.totalPages &&
                    (_p.fontsInstalled ||
                        next <= MushafReaderProvider.previewLimit)) {
                  _p.tryNavigateTo(next);
                }
              },
            )
          else
            SizedBox(width: 48 * ResponsiveHelper.scaleFactor(context)),
          // Play/pause audio
          if (_p.isLoadingAudio)
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: _p.isPlaying || _p.playingLabel != null
                  ? _p
                        .togglePlayPause // already loaded → just pause/resume
                  : _p.onPlayPressed, // nothing loaded → fetch and play
              child: Container(
                width: 40 * ResponsiveHelper.scaleFactor(context),
                height: 40 * ResponsiveHelper.scaleFactor(context),
                decoration: const BoxDecoration(
                  color: _kSecondaryDark,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _p.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28 * ResponsiveHelper.scaleFactor(context),
                ),
              ),
            ),
          // Page indicator
          Text(
            '${_p.currentPage} / ${_p.fontsInstalled ? MushafReaderProvider.totalPages : MushafReaderProvider.previewLimit}',
            style: const TextStyle(color: textColor, fontSize: 13),
          ),
          // Next page (hidden on first page)
          if (_p.currentPage > 1)
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              color: textColor,
              onPressed: () {
                final prev = _p.currentPage - 1;
                if (prev >= 1) _p.tryNavigateTo(prev);
              },
            )
          else
            SizedBox(width: 48 * ResponsiveHelper.scaleFactor(context)),
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
