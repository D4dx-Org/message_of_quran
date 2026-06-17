import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/models/tajweed_word_model.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/preface_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/tajweed_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/tajweed_html_service.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/cross_reference_parser.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/utils/surah_place_localizer.dart';
import 'package:the_message_of_the_quran/core/utils/translation_alignment.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/responsive_content_wrapper.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/core/widgets/scroll_to_top_button.dart';
import 'package:the_message_of_the_quran/core/widgets/pinch_zoom_view.dart';
import 'package:the_message_of_the_quran/features/bookmark_screen/presentation/bookmark_conflict_dialog.dart';
import 'package:the_message_of_the_quran/features/main_screen/presentation/main_screen.dart';
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/surah_screen_app_bar.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/cross_reference_sheet.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/show_translation_gate.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/interpretation_note_marker.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_auto_advance.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/tajweed_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/reading_progress_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/audio_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

String _toArabicNumerals(int value) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value
      .toString()
      .split('')
      .map((digit) => arabicDigits[int.parse(digit)])
      .join();
}

class _SurahBismillahHeader extends StatelessWidget {
  const _SurahBismillahHeader({required this.glyphText});

  static const String _fallbackText =
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

  final String glyphText;

  @override
  Widget build(BuildContext context) {
    final trimmedGlyph = glyphText.trim();
    final hasGlyph = trimmedGlyph.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
      child: Center(
        child: Text(
          hasGlyph ? trimmedGlyph : _fallbackText,
          textAlign: TextAlign.center,
          textDirection: hasGlyph ? TextDirection.ltr : TextDirection.rtl,
          style: AppTextTheme.forewordBismillah(context).copyWith(
            fontFamily: hasGlyph ? 'QCF_BSML' : null,
            fontSize: hasGlyph ? 30 : 28,
            height: hasGlyph ? 1.35 : 1.6,
          ),
        ),
      ),
    );
  }
}

class _SurahMainScreenRedirect extends StatelessWidget {
  const _SurahMainScreenRedirect({required this.targetIndex});

  final int targetIndex;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Provider.of<HomeProvider>(context, listen: false).changeIndex(targetIndex);
    });
    return const MainScreen();
  }
}

/// Bottom-sheet content for the "Jump to Ayah" picker with an ayah-number
/// search field. Owns its own [TextEditingController] so it is disposed safely
/// after the sheet's close animation completes.
class _JumpToAyahSheet extends StatefulWidget {
  const _JumpToAyahSheet({
    required this.arabicBlockList,
    required this.isMalayalam,
    required this.scrollController,
    required this.onSelect,
  });

  final List<ArabicBlockModel> arabicBlockList;
  final bool isMalayalam;
  final ScrollController scrollController;

  /// Called with the original block index and the ayah-start number when a row
  /// is tapped.
  final void Function(int blockIndex, int ayaStart) onSelect;

  @override
  State<_JumpToAyahSheet> createState() => _JumpToAyahSheetState();
}

class _JumpToAyahSheetState extends State<_JumpToAyahSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMl = widget.isMalayalam;
    final query = _searchController.text.trim();
    final typed = int.tryParse(query);
    // Filter blocks by typed ayah number while preserving each block's original
    // index so the jump/highlight logic stays correct.
    final entries = <MapEntry<int, ArabicBlockModel>>[];
    for (var i = 0; i < widget.arabicBlockList.length; i++) {
      final block = widget.arabicBlockList[i];
      if (query.isEmpty) {
        entries.add(MapEntry(i, block));
        continue;
      }
      final start = block.verseFrom ?? i + 1;
      final end = block.verseTo ?? i + 1;
      final matchesRange = typed != null && typed >= start && typed <= end;
      final matchesText =
          start.toString().contains(query) || end.toString().contains(query);
      if (matchesRange || matchesText) {
        entries.add(MapEntry(i, block));
      }
    }

    return Column(
      children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            isMl ? 'ആയത്തിലേക്ക് പോകുക' : 'Jump to Ayah',
            style: AppTextTheme.localizedLabel(
              isMalayalam: isMl,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Ayah number search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: TextField(
            controller: _searchController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            style: AppTextTheme.localizedLabel(
              isMalayalam: isMl,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: isMl ? 'ആയത്ത് തിരയുക' : 'Search ayah',
              hintStyle: AppTextTheme.localizedLabel(
                isMalayalam: isMl,
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    isMl ? 'ആയത്ത് കണ്ടെത്തിയില്ല' : 'No ayah found',
                    style: AppTextTheme.localizedLabel(
                      isMalayalam: isMl,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.separated(
                  controller: widget.scrollController,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 64),
                  itemBuilder: (_, listIndex) {
                    final i = entries[listIndex].key;
                    final block = entries[listIndex].value;
                    final start = block.verseFrom ?? i + 1;
                    final end = block.verseTo ?? i + 1;
                    final startText = start.toString();
                    final label = start == end
                        ? formatAyahReferenceLabel(start, isMalayalam: isMl)
                        : formatAyahRangeLabel(start, end, isMalayalam: isMl);
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.appThemePrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          startText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        label,
                        style: AppTextTheme.localizedLabel(
                          isMalayalam: isMl,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        final ayaStart = block.verseFrom ?? i + 1;
                        widget.onSelect(i, ayaStart);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class SurahScreen extends StatefulWidget {
  /// When set, the screen scrolls to the ayah block with this ayaStart after
  /// the content loads (used from BookmarkScreen).
  final int? scrollToAyahId;

  const SurahScreen({super.key, this.scrollToAyahId});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _itemKeys = [];
  bool _showScrollToTop = false;
  bool _showBottomSurahNavOverlay = false;
  double? _deepLinkCacheExtent;

  /// Cached provider references — safe to use in dispose().
  late SurahProvider _surahProv;
  late LastReadProvider _lastReadProv;
  late ReadingProgressProvider _readingProgressProv;

  /// The ayaStart value of the first fully-visible ayah block.
  int? _lastKnownAyahStart;

  /// The ayaEnd value of the last visible ayah block (for progress tracking).
  int? _lastVisibleAyahEnd;

  /// AudioProvider whose changes we're listening to for auto-scroll.
  AudioProvider? _listeningAudioProv;

  /// Tracks the last ayah we auto-scrolled to, to avoid duplicate scrolls.
  int? _lastScrolledPlayingAyahId;

  /// Tracks the surah index so we can detect jumps and reset scroll.
  int? _lastSurahIndex;

  bool _surahTransitionPending = false;

  /// Whether the current surah has a preface in the database.
  bool _hasPreface = false;

  int? _temporarilyHighlightedAyahId;
  Timer? _temporaryAyahHighlightTimer;

  Rect? _sharePositionOriginFor(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize ||
        renderObject.size.isEmpty) {
      return null;
    }

    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _surahProv = Provider.of<SurahProvider>(context, listen: false);
    _lastReadProv = Provider.of<LastReadProvider>(context, listen: false);
    _readingProgressProv = Provider.of<ReadingProgressProvider>(
      context,
      listen: false,
    );

    // Re-wire the AudioProvider listener whenever the provider instance changes.
    final newAudioProv = Provider.of<AudioProvider>(context, listen: false);
    if (_listeningAudioProv != newAudioProv) {
      _listeningAudioProv?.removeListener(_onAudioProviderChanged);
      _listeningAudioProv = newAudioProv;
      newAudioProv.addListener(_onAudioProviderChanged);
    }

    // Sync keys with arabicBlockList length AND surah index to avoid
    // reusing GlobalKey instances across different surahs.
    final newLen = _surahProv.arabicBlockList.length;
    if (_itemKeys.length != newLen || _lastSurahIndex != _surahProv.index) {
      _itemKeys = List.generate(newLen, (_) => GlobalKey());
    }

    // When the surah changes (e.g. Jump-to-Surah), stop any playing audio
    // so the stale onAyahComplete callback doesn't reference the old
    // translationList, then reset scroll to top.
    // Skip stopAudio during auto-advance so continuous playback isn't killed.
    if (_lastSurahIndex != null && _lastSurahIndex != _surahProv.index) {
      if (!newAudioProv.isProgrammaticSurahTransition) {
        newAudioProv.stopAudio();
      }
      _lastKnownAyahStart = null;
      _lastVisibleAyahEnd = null;
      _lastScrolledPlayingAyahId = null;
      _resetTemporaryJumpHighlight(rebuild: false);
      _showBottomSurahNavOverlay = false;
      _surahTransitionPending = false;
      _checkPrefaceAvailability();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.scrollToAyahId == null && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
    _lastSurahIndex = _surahProv.index;
    _checkPrefaceAvailability();
  }

  /// Queries the database to check whether the current surah has a preface.
  Future<void> _checkPrefaceAvailability() async {
    if (_surahProv.surahList.isEmpty ||
        _surahProv.index >= _surahProv.surahList.length) {
      return;
    }
    final surahNumber = _surahProv.surahList[_surahProv.index].surahNumber;
    final isMl = context.read<LanguageProvider>().isMalayalam;
    final prefaces = await PrefaceDbHelper.getPrefaceBySurahId(
      surahNumber,
      malayalam: isMl,
    );
    if (!mounted) return;
    setState(() {
      _hasPreface = prefaces.isNotEmpty;
    });
  }

  bool _useDesktopWebReaderLayout(BuildContext context) {
    if (!kIsWeb) return false;
    return MediaQuery.sizeOf(context).width >= 980;
  }

  bool _useCompactWebReaderLayout(BuildContext context) {
    return kIsWeb && !_useDesktopWebReaderLayout(context);
  }

  Widget _buildDesktopReaderHeader(
    BuildContext context,
    SurahProvider controller,
  ) {
    if (controller.surahList.isEmpty || controller.index >= controller.surahList.length) {
      return const SizedBox.shrink();
    }

    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final surah = controller.surahList[controller.index];

    return SurahInfoStrip(
          surahName: surah.name,
          surahTranslation: surah.description,
          malayalamName: surah.malayalamName,
          place: surah.place,
          ordinalLabel: surah.ordinalLabel,
          surahNumber: surah.surahNumber,
          isMalayalam: isMalayalam,
          showPrevious: controller.index < controller.surahList.length - 1,
          showNext: controller.index > 0,
          onPrevious: () => controller.onSwipe(false),
          onNext: () => controller.onSwipe(true),
          trailingActions: SurahBannerActions(
            isMalayalam: isMalayalam,
            onPlayPressed: _restartSurahPlayback,
            onInfoPressed: _hasPreface
                ? () => _showSurahInfo(context, controller)
                : null,
            compact: true,
          ),
        );
  }

  Widget _buildSurahAppBarTitleControls(SurahProvider controller) {
    if (controller.surahList.isEmpty || controller.index >= controller.surahList.length) {
      return CommonAppBar.brandLogo(context);
    }

    final scale = ResponsiveHelper.scaleFactor(context);
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final surah = controller.surahList[controller.index];
    final currentAyahNumber =
        _lastKnownAyahStart ?? (controller.arabicBlockList.firstOrNull?.verseFrom ?? 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final logoWidth = maxWidth < 250
            ? 64.0 * scale
            : maxWidth < 340
                ? 80.0 * scale
                : 108.0 * scale;

        final chip = SurahHeaderControls(
          isMalayalam: isMalayalam,
          surahList: controller.surahList,
          currentSurahNumber: surah.surahNumber,
          arabicBlockList: controller.arabicBlockList,
          currentAyahNumber: currentAyahNumber,
          onAyahSelected: _jumpToAyah,
          compact: true,
          showActions: false,
        );

        return Row(
          children: [
            SizedBox(
              width: logoWidth,
              child: CommonAppBar.brandLogo(
                context,
              ),
            ),
            SizedBox(width: maxWidth < 300 ? 4 : 8),
            Flexible(
              fit: FlexFit.loose,
              child: chip,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSurahWebActions(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 640;
    final actions = CommonWebAppBarActions(
      selectedPageIndex: null,
      onPageSelected: (index) {
        unawaited(_navigateToMainTab(index));
      },
      compact: true,
      showSearch: false,
      showLabels: !isNarrow,
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: actions,
    );
  }

  Future<void> _navigateToMainTab(int tabIndex) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);

    // Settings: open as a dialog overlay so audio and scroll position are preserved.
    if (tabIndex == 3) {
      _saveLastRead();
      if (!mounted) return;
      showSettingsDialog(context);
      return;
    }

    _saveLastRead();
    await context.read<AudioProvider>().stopAudio();
    if (!mounted) return;

    await navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => _SurahMainScreenRedirect(targetIndex: tabIndex),
      ),
      (route) => false,
    );
  }

  Future<void> _toggleSurahBookmark({
    required BuildContext context,
    required SurahProvider controller,
    required int surahNumber,
    required int ayahId,
    required bool isBookmarked,
    String? ayaText,
  }) async {
    const navigationTarget = BookmarkNavigationTarget.surah;

    if (isBookmarked) {
      await controller.onBookMarkRemoveByAyah(
        surahNumber,
        ayahId,
        navigationTarget: navigationTarget,
      );
      return;
    }

    final surah = controller.surahList[controller.index];
    var replaceSameSurah = false;

    if (controller.hasSurahBookmarkConflict(
      surahNumber,
      ayahId,
      navigationTarget: navigationTarget,
    )) {
      final resolution = await showBookmarkConflictDialog(
        context,
        navigationTarget: navigationTarget,
        surahName: surah.name,
      );
      if (!mounted || resolution == null) return;
      replaceSameSurah = resolution == BookmarkConflictResolution.replace;
    }

    await controller.onBookMarkAdd(
      surahNumber,
      ayahId,
      surahName: surah.name,
      ayaText: ayaText,
      surahArabicName: surah.arabicName,
      navigationTarget: navigationTarget,
      replaceSameSurah: replaceSameSurah,
    );
  }

  void _resetTemporaryJumpHighlight({bool rebuild = true}) {
    _temporaryAyahHighlightTimer?.cancel();
    _temporaryAyahHighlightTimer = null;

    if (_temporarilyHighlightedAyahId == null) return;

    if (rebuild && mounted) {
      setState(() {
        _temporarilyHighlightedAyahId = null;
      });
      return;
    }

    _temporarilyHighlightedAyahId = null;
  }

  void _showTemporaryJumpHighlight(int ayahId) {
    if (!mounted) return;

    _temporaryAyahHighlightTimer?.cancel();
    setState(() {
      _temporarilyHighlightedAyahId = ayahId;
    });

    _temporaryAyahHighlightTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _temporarilyHighlightedAyahId = null;
        _temporaryAyahHighlightTimer = null;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // Note: we deliberately do NOT show a loading overlay for deep-link
    // opens. The surah opens at ayah 1 like any normal surah open
    // (matching the behaviour of the other chips like Yaseen, Al Mulk,
    // etc.), and once data + first layout are ready we scroll to the
    // target ayah. This avoids the shaded splash flash before scrolling
    // to e.g. Ayatul Kursi.
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final surahProv = Provider.of<SurahProvider>(context, listen: false);

      // Only reload if data isn't already present (e.g. pre-loaded by
      // selectSurahByNumber from the bookmark / last-read flow). This avoids
      // regenerating GlobalKeys a second time which would delay the scroll.
      if (surahProv.arabicBlockList.isEmpty) {
        await surahProv.getAyasForCurrentSurah();
      }
      if (!mounted) return;

      // Wire audio-completion callback for continuous playback.
      final audioProv = Provider.of<AudioProvider>(context, listen: false);
      final playSettings = Provider.of<PlaySettingsProvider>(
        context,
        listen: false,
      );
      audioProv.onAyahComplete = (surahNumber, completedIndex) {
        // No mounted check — AudioProvider is app-level and must continue
        // playing even after this screen is popped.
        if (playSettings.playMode == PlayMode.continuous) {
          final blocks = surahProv.arabicBlockList;
          final nextIndex = completedIndex + 1;
          if (nextIndex < blocks.length) {
            final nextAyaStart = blocks[nextIndex].verseFrom ?? nextIndex + 1;
            final nextAyaEnd = blocks[nextIndex].verseTo ?? nextAyaStart;
            audioProv.playAyah(
              surahNumber: surahNumber,
              ayahId: nextAyaStart,
              ayahEndId: nextAyaEnd,
              translationIndex: nextIndex,
              reciter: playSettings.selectedReciter,
              playbackSpeed: playSettings.playbackSpeed,
            );
          } else {
            // Last block of the surah finished — advance to the next surah.
            _advanceToNextSurah(
              surahProv: surahProv,
              audioProv: audioProv,
              playSettings: playSettings,
            );
          }
        }
      };

      // Surah is already showing at ayah 1; smoothly animate down to the
      // target ayah after a brief pause so the user clearly sees the surah
      // open at its first ayah (matching the feel of other chips like
      // Yaseen / Al Mulk) before it scrolls to e.g. Ayatul Kursi (255).
      if (widget.scrollToAyahId != null && mounted) {
        unawaited(_animateToAyahAfterLoad(widget.scrollToAyahId!));
      }

      // Run an initial visibility scan so short surahs that fit on one
      // screen (no scroll event) still record the visible ayahs.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onScroll();
      });
    });
  }

  /// Scans visible item keys to find the first ayah block whose top edge is
  /// on-screen, caching the result for use in [_saveLastRead].
  /// Also updates the scroll-to-top FAB visibility.
  void _onScroll() {
    final hasClients = _scrollController.hasClients;
    final showScrollToTop = hasClients && _scrollController.offset > 200;
    final blocks = _surahProv.arabicBlockList;

    if (blocks.isEmpty) {
      if (showScrollToTop != _showScrollToTop || _showBottomSurahNavOverlay) {
        setState(() {
          _showScrollToTop = showScrollToTop;
          _showBottomSurahNavOverlay = false;
        });
      }
      return;
    }

    // Track the first fully-visible ayah and the last visible ayah.
    final screenHeight = MediaQuery.of(context).size.height;
    bool foundFirst = false;
    int? lastEnd;
    for (int i = 0; i < _itemKeys.length && i < blocks.length; i++) {
      final ctx = _itemKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final topY = box.localToGlobal(Offset.zero).dy;
      if (topY >= 0 && !foundFirst) {
        _lastKnownAyahStart = blocks[i].verseFrom ?? i + 1;
        foundFirst = true;
      }
      if (foundFirst && topY < screenHeight) {
        lastEnd = blocks[i].verseTo ?? i + 1;
      }
      if (topY >= screenHeight) break;
    }

    final totalAyahEnd = blocks.last.verseTo ?? blocks.length;
    final showBottomSurahNavOverlay =
        hasClients &&
        lastEnd != null &&
        lastEnd >= totalAyahEnd &&
        _scrollController.position.extentAfter <= 12;

    if (showScrollToTop != _showScrollToTop ||
        showBottomSurahNavOverlay != _showBottomSurahNavOverlay) {
      setState(() {
        _showScrollToTop = showScrollToTop;
        _showBottomSurahNavOverlay = showBottomSurahNavOverlay;
      });
    }

    if (lastEnd != null && lastEnd != _lastVisibleAyahEnd) {
      _lastVisibleAyahEnd = lastEnd;
      // Update reading progress in real-time during scroll.
      if (_surahProv.surahList.isNotEmpty &&
          _surahProv.index >= 0 &&
          _surahProv.index < _surahProv.surahList.length) {
        final surah = _surahProv.surahList[_surahProv.index];
        _readingProgressProv.updateProgress(
          surahNumber: surah.surahNumber,
          ayahNumber: lastEnd,
          totalAyahs: surah.ayathCount,
        );
      }
    }
  }

  bool _canNavigateToAdjacentSurah(bool isLeft) {
    if (_surahProv.surahList.isEmpty) return false;
    final targetIndex = isLeft ? _surahProv.index - 1 : _surahProv.index + 1;
    return targetIndex >= 0 && targetIndex < _surahProv.surahList.length;
  }

  Future<void> _navigateToAdjacentSurah(bool isLeft) async {
    if (_surahTransitionPending || !_canNavigateToAdjacentSurah(isLeft)) {
      return;
    }

    final currentIndex = _surahProv.index;
    _surahTransitionPending = true;
    await _surahProv.onSwipe(isLeft);

    if (!mounted) return;
    if (_surahProv.index == currentIndex) {
      _surahTransitionPending = false;
    }
  }

  Widget _buildBottomSurahNavButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final navButtonColor = isDarkMode
        ? Theme.of(context).cardColor
        : const Color.fromRGBO(255, 250, 234, 1);
    final iconColor = isDarkMode ? Colors.white : AppTheme.appIconTheme;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.18)
        : AppTheme.appIconTheme.withValues(alpha: 0.24);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: navButtonColor,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
      ),
    );
  }

  void _jumpToAyah(int ayaStart) {
    final idx = _findAyahBlockIndex(_surahProv.arabicBlockList, ayaStart);
    if (idx < 0) return;

    if (idx == 0) {
      _ensureAyahVisible(0);
      _showTemporaryJumpHighlight(ayaStart);
      return;
    }

    unawaited(_animateToBlockIndex(idx, ayaStartForHighlight: ayaStart));
  }

  Future<void> _restartSurahPlayback() async {
    if (!mounted ||
        _surahProv.surahList.isEmpty ||
        _surahProv.index < 0 ||
        _surahProv.index >= _surahProv.surahList.length ||
        _surahProv.arabicBlockList.isEmpty) {
      return;
    }

    final firstBlock = _surahProv.arabicBlockList.first;
    final ayahStart = firstBlock.verseFrom ?? 1;
    final ayahEnd = firstBlock.verseTo ?? ayahStart;
    final surahNumber = _surahProv.surahList[_surahProv.index].surahNumber;
    final playSettings = context.read<PlaySettingsProvider>();

    await context.read<AudioProvider>().playAyah(
      surahNumber: surahNumber,
      ayahId: ayahStart,
      ayahEndId: ayahEnd,
      translationIndex: 0,
      reciter: playSettings.selectedReciter,
      playbackSpeed: playSettings.playbackSpeed,
    );
  }

  Widget _buildFinalAyahNavSection(BuildContext context) {
    final canGoNext = _canNavigateToAdjacentSurah(false);
    final canGoPrevious = _canNavigateToAdjacentSurah(true);

    return Column(
      children: [
        SizedBox(
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(
                left: 0,
                right: 0,
                child: Divider(thickness: 0.5, height: 1),
              ),
              if (canGoNext || canGoPrevious)
                IgnorePointer(
                  ignoring: !_showBottomSurahNavOverlay,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    offset: _showBottomSurahNavOverlay
                        ? Offset.zero
                        : const Offset(0, 0.2),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      opacity: _showBottomSurahNavOverlay ? 1 : 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canGoNext)
                            _buildBottomSurahNavButton(
                              context: context,
                              icon: Icons.chevron_left_rounded,
                              tooltip: 'Next surah',
                              onPressed: () => _navigateToAdjacentSurah(false),
                            ),
                          if (canGoNext && canGoPrevious)
                            const SizedBox(width: 10),
                          if (canGoPrevious)
                            _buildBottomSurahNavButton(
                              context: context,
                              icon: Icons.chevron_right_rounded,
                              tooltip: 'Previous surah',
                              onPressed: () => _navigateToAdjacentSurah(true),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  /// Advances to the next surah and starts playing its first block.
  /// Called from [onAyahComplete] when continuous playback reaches the end
  /// of the current surah.
  Future<void> _advanceToNextSurah({
    required SurahProvider surahProv,
    required AudioProvider audioProv,
    required PlaySettingsProvider playSettings,
  }) async {
    // No next surah available (last surah in the list).
    if (surahProv.index >= surahProv.surahList.length - 1) return;

    await runSurahAutoAdvance(
      navigateToNextSurah: () => surahProv.onSwipe(false),
      readBlocks: () => surahProv.arabicBlockList,
      readSurahNumber: () => surahProv.surahList[surahProv.index].surahNumber,
      startPlayback:
          ({
            required int surahNumber,
            required int ayahStart,
            required int ayahEnd,
            required int translationIndex,
          }) {
            return audioProv.playAyah(
              surahNumber: surahNumber,
              ayahId: ayahStart,
              ayahEndId: ayahEnd,
              translationIndex: translationIndex,
              reciter: playSettings.selectedReciter,
              playbackSpeed: playSettings.playbackSpeed,
            );
          },
      setAutoAdvancing: (isAutoAdvancing) {
        audioProv.setProgrammaticSurahTransition(isAutoAdvancing);
      },
    );
  }

  void _handleContinuousModeSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 250) return;

    if (velocity > 0) {
      _navigateToAdjacentSurah(false);
    } else {
      _navigateToAdjacentSurah(true);
    }
  }

  /// Saves the current surah + first-visible ayah as the last-read position.
  void _saveLastRead() {
    if (_surahProv.surahList.isEmpty ||
        _surahProv.index < 0 ||
        _surahProv.index >= _surahProv.surahList.length) {
      return;
    }
    final surah = _surahProv.surahList[_surahProv.index];
    final ayahId = _lastKnownAyahStart ?? 1;
    // Update progress first so _totalMap is populated before the banner
    // rebuilds in response to LastReadProvider's notification.
    _readingProgressProv.updateProgress(
      surahNumber: surah.surahNumber,
      ayahNumber: _lastVisibleAyahEnd ?? ayahId,
      totalAyahs: surah.ayathCount,
    );
    _lastReadProv.saveLastRead(
      surahNumber: surah.surahNumber,
      surahName: surah.name,
      ayahId: ayahId,
    );
  }

  /// Called whenever AudioProvider notifies. Auto-scrolls to the newly
  /// playing ayah when [playingAyahId] changes.
  void _onAudioProviderChanged() {
    final audio = _listeningAudioProv;
    if (audio == null) return;
    final playbackError = audio.consumePendingPlaybackError();
    if (playbackError != null) {
      _showAudioPlaybackError(playbackError);
    }
    final playingId = audio.playingAyahId;

    // Reset the dedup guard when audio becomes fully inactive so that
    // replaying the same ayah later still triggers a scroll.
    if (!audio.isActive) {
      _lastScrolledPlayingAyahId = null;
      return;
    }

    if (playingId == null) return;
    if (playingId == _lastScrolledPlayingAyahId) return;

    // Accept the new ayah as long as the player is active (playing,
    // loading, or buffering). Using isActive instead of isPlaying ensures
    // we don't miss the index-change notification that fires while the
    // next track is still buffering.
    _lastScrolledPlayingAyahId = playingId;
    _scrollToPlayingAyah(playingId);
  }

  void _showAudioPlaybackError(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  /// Scrolls so that the translation row containing [ayahId] is visible.
  ///
  /// Strategy:
  /// 1. Defer to a post-frame callback so we never run mid-build.
  /// 2. If the item's RenderObject is already in the tree → ensureVisible.
  /// 3. If it is outside the lazily-rendered viewport → jump proportionally to
  ///    pull it into view, then retry ensureVisible once the layout settles.
  void _scrollToPlayingAyah(int ayahId) {
    if (!mounted) return;
    final blocks = _surahProv.arabicBlockList;
    final idx = blocks.indexWhere((block) {
      final start = block.verseFrom ?? 0;
      final end = block.verseTo ?? 0;
      return ayahId >= start && ayahId <= end;
    });
    if (idx < 0 || idx >= _itemKeys.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureAyahVisible(idx);
    });
  }

  /// Internal helper — tries ensureVisible; falls back to a proportional jump
  /// + retry when the item is not yet in the render tree.
  void _ensureAyahVisible(int idx, {bool isRetry = false}) {
    if (!mounted) return;
    if (idx < 0 || idx >= _itemKeys.length) return;

    // For the very first ayah, scroll all the way to the top so the pinned
    // SliverAppBar (banner) is fully expanded and ayah 1 is not hidden behind it.
    if (idx == 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    final key = _itemKeys[idx];
    if (key.currentContext != null) {
      // alignment: 0.0 lets Flutter's SliverLayout-aware showOnScreen place
      // the item just below the pinned header rather than at raw viewport 0%.
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Item is not rendered yet (lazily outside viewport). Jump proportionally
    // to pull it into the render tree, then retry.
    if (isRetry) return; // avoid infinite retries
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final fraction = idx / _surahProv.arabicBlockList.length;
    _scrollController.jumpTo((fraction * maxExtent).clamp(0, maxExtent));

    // After the jump, re-layout happens in the next frame — retry then.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureAyahVisible(idx, isRetry: true);
    });
  }

  @override
  void dispose() {
    _temporaryAyahHighlightTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _listeningAudioProv?.removeListener(_onAudioProviderChanged);
    _listeningAudioProv?.stopAudio();
    super.dispose();
  }

  int _findAyahBlockIndex(List<ArabicBlockModel> blocks, int ayaStart) {
    var idx = blocks.indexWhere((block) => block.verseFrom == ayaStart);
    if (idx >= 0) return idx;
    return blocks.indexWhere((block) {
      final start = block.verseFrom ?? 0;
      final end = block.verseTo ?? 0;
      return start <= ayaStart && ayaStart <= end;
    });
  }

  double? _estimateScrollOffsetForIndex(int idx) {
    if (!_scrollController.hasClients) return null;

    double measuredExtentSum = 0;
    int measuredCount = 0;
    int? nearestMeasuredIndex;
    double? nearestMeasuredOffset;

    for (int i = 0; i < _itemKeys.length; i++) {
      final ctx = _itemKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      measuredExtentSum += box.size.height;
      measuredCount++;

      final viewport = RenderAbstractViewport.of(box);
      final revealOffset = viewport.getOffsetToReveal(box, 0.0).offset;
      if (nearestMeasuredIndex == null ||
          (i - idx).abs() < (nearestMeasuredIndex - idx).abs()) {
        nearestMeasuredIndex = i;
        nearestMeasuredOffset = revealOffset;
      }
    }

    if (measuredCount == 0 ||
        nearestMeasuredIndex == null ||
        nearestMeasuredOffset == null) {
      return null;
    }

    final averageExtent = measuredExtentSum / measuredCount;
    final estimatedOffset =
        nearestMeasuredOffset + ((idx - nearestMeasuredIndex) * averageExtent);
    final maxExtent = _scrollController.position.maxScrollExtent;
    return estimatedOffset.clamp(0.0, maxExtent).toDouble();
  }

  /// Used by deep-link opens (Ayatul Kursi chip, etc.): waits one frame so
  /// ayah 1 paints, then performs a SINGLE smooth scroll directly to
  /// [ayaStart]. Uses an iterative invisible pre-warm `jumpTo` to build
  /// the SliverList items around the target so we can read the target's
  /// EXACT scroll offset from its RenderBox before we start the visible
  /// animation. The visible animation is then a single `animateTo` to
  /// that locked offset — no post-animation correction, so the page
  /// stops cleanly at the target ayah and does not continue scrolling.
  Future<void> _animateToAyahAfterLoad(int ayaStart) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scrollController.hasClients) return;

    // Brief pause so ayah 1 is clearly visible before the scroll starts.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || !_scrollController.hasClients) return;

    final blocks = _surahProv.arabicBlockList;
    final idx = _findAyahBlockIndex(blocks, ayaStart);
    if (idx < 0 || idx >= _itemKeys.length) return;

    await _animateToBlockIndex(idx, ayaStartForHighlight: ayaStart);
  }

  /// Precisely scrolls to the block at [idx] and briefly highlights
  /// [ayaStartForHighlight]. Pre-warms the lazy [SliverList] via an enlarged
  /// cache window so distant ayahs (e.g. 40, 50, 100) are built before we read
  /// their EXACT scroll offset from the target's RenderBox — then performs a
  /// SINGLE smooth animation so the page lands cleanly on the target ayah.
  Future<void> _animateToBlockIndex(
    int idx, {
    required int ayaStartForHighlight,
  }) async {
    if (!mounted || !_scrollController.hasClients) return;
    if (idx < 0 || idx >= _itemKeys.length) return;

    final blocks = _surahProv.arabicBlockList;
    var shouldHighlightTargetAyah = false;

    try {
      shouldHighlightTargetAyah = true;
      if (_deepLinkCacheExtent != 120000.0) {
        setState(() => _deepLinkCacheExtent = 120000.0);
      }

      // Enable the larger cache window only after the route is already
      // visible so the first navigation frame stays lightweight.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) return;

      // Read the EXACT target offset from the target's RenderBox if its
      // element is already built; otherwise fall back to the measured-index
      // estimator so we still perform exactly one visible animation.
      double? lockedTargetOffset;
      final targetCtx = _itemKeys[idx].currentContext;
      if (targetCtx != null) {
        // No async gap here — we read render geometry synchronously.
        // ignore: use_build_context_synchronously
        final box = targetCtx.findRenderObject() as RenderBox?;
        if (box != null && box.attached) {
          final viewport = RenderAbstractViewport.of(box);
          lockedTargetOffset = viewport.getOffsetToReveal(box, 0.0).offset;
        }
      }
      final maxExtent = _scrollController.position.maxScrollExtent;
      lockedTargetOffset ??=
          _estimateScrollOffsetForIndex(idx) ??
          ((idx / blocks.length) * maxExtent).clamp(0.0, maxExtent).toDouble();
      final clampedTarget = lockedTargetOffset
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();

      // ONE smooth animation to the locked target offset.
      await _scrollController.animateTo(
        clampedTarget,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
    } finally {
      if (mounted && shouldHighlightTargetAyah) {
        _showTemporaryJumpHighlight(ayaStartForHighlight);
      }
      if (mounted && _deepLinkCacheExtent != null) {
        setState(() => _deepLinkCacheExtent = null);
      }
    }
  }

  void _showSurahInfo(BuildContext context, SurahProvider controller) {
    if (controller.surahList.isEmpty ||
        controller.index >= controller.surahList.length) {
      return;
    }
    final surah = controller.surahList[controller.index];
    final isMl = context.read<LanguageProvider>().isMalayalam;
    final surahTitle = formatSurahDisplayNameLine(
      isMalayalam: isMl,
      surahName: surah.name,
      surahTranslation: surah.description,
      malayalamName: surah.malayalamName,
      surahNumber: surah.surahNumber,
    );

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;
        final colorScheme = theme.colorScheme;
        final panelColor = isDark ? theme.cardColor : Colors.white;
        final borderColor = isDark
            ? Colors.white.withValues(alpha: 0.12)
            : (theme.dividerTheme.color ?? colorScheme.outlineVariant);
        final primaryColor = isDark ? Colors.white : AppTheme.appThemePrimary;
        final size = MediaQuery.sizeOf(dialogContext);
        const double maxDialogWidth = 620;
        final double hInset = size.width < 640
            ? 12.0
            : ((size.width - maxDialogWidth) / 2).clamp(24.0, double.infinity);
        final double maxHeight =
            (size.height * 0.82).clamp(300.0, 700.0);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: hInset,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxDialogWidth,
                maxHeight: maxHeight,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: surah number | title | close button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${isMl ? 'സൂറത്ത്' : 'Surah'} : ${surah.surahNumber}',
                            style: AppTextTheme.localizedLabel(
                              isMalayalam: isMl,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              surahTitle,
                              style: AppTextTheme.localizedTitle(
                                isMalayalam: isMl,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? colorScheme.onSurface
                                    : AppTheme.appThemePrimary,
                                height: 1.25,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Metadata chips
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _infoChip(
                            dialogContext,
                            localizeSurahPlace(surah.place, isMalayalam: isMl),
                            isMalayalam: isMl,
                          ),
                          _infoChip(
                            dialogContext,
                            '${surah.ayathCount}',
                            isMalayalam: isMl,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Preface sections
                    Flexible(
                      child: FutureBuilder(
                        future: PrefaceDbHelper.getPrefaceBySurahId(
                          surah.surahNumber,
                          malayalam: isMl,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'Failed to load surah info.',
                                  style: AppTextTheme.popinsDefault(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }
                          final prefaceList = snapshot.data ?? [];
                          if (prefaceList.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No description available for this surah.',
                                  style: AppTextTheme.popinsDefault(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: prefaceList.length,
                            itemBuilder: (_, i) {
                              final preface = prefaceList[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (preface.prefaceSubTitle.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          preface.prefaceSubTitle,
                                          style: AppTextTheme.localizedLabel(
                                            isMalayalam: isMl,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      preface.prefaceText,
                                      style: AppTextTheme.localizedBody(
                                        isMalayalam: isMl,
                                        fontSize: 14,
                                        height: 1.6,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(
    BuildContext context,
    String value, {
    required bool isMalayalam,
  }) {
    final isDark = isDarkMode(context: context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.outlineVariant : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: colorScheme.outline.withValues(alpha: 0.6))
            : null,
      ),
      child: Text(
        value,
        style: AppTextTheme.localizedLabel(
          isMalayalam: isMalayalam,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark
              ? colorScheme.onSurface
              : AppTheme.appThemePrimary,
        ),
      ),
    );
  }

  /// Splits a combined Arabic block text at verse-end markers (﴿N﴾) and
  /// returns a list of [TextSpan]s where only the segment belonging to
  /// [playingAyahId] is coloured with [highlightColor].
  /// Selected ayahs (via [controller]) get a background highlight.
  Color? _ayahBackgroundColor({
    required int ayahNumber,
    required SurahProvider controller,
  }) {
    if (_temporarilyHighlightedAyahId == ayahNumber) {
      return appBarAccentFillColor(context, alpha: 0.22);
    }

    if (controller.isAyahSelected(ayahNumber)) {
      return const Color(0xFF338FCC).withValues(alpha: 0.25);
    }

    return null;
  }

  List<TextSpan> _buildArabicSpans(
    String arabicText,
    int verseFrom,
    int? playingAyahId,
    TextStyle baseStyle,
    Color highlightColor,
    SurahProvider controller,
  ) {
    // Matches Quran verse-end markers: ﴿N﴾ (Arabic-Indic or Western digits).
    final markerRegex = RegExp(r'﴿[\u0660-\u06690-9]+﴾');
    final matches = markerRegex.allMatches(arabicText).toList();

    if (matches.isEmpty) {
      final isPlaying = playingAyahId == verseFrom;
      return [
        TextSpan(
          text: arabicText,
          style: baseStyle.copyWith(
            color: isPlaying ? highlightColor : null,
            backgroundColor: _ayahBackgroundColor(
              ayahNumber: verseFrom,
              controller: controller,
            ),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => controller.onAyahTap(verseFrom),
        ),
      ];
    }

    final spans = <TextSpan>[];
    int pos = 0;
    int currentAyah = verseFrom;

    for (final match in matches) {
      final segment =
          '${arabicText.substring(pos, match.start)} ${arabicText.substring(match.start, match.end)} ';
      final isPlaying = playingAyahId == currentAyah;
      final ayahNum = currentAyah;
      spans.add(
        TextSpan(
          text: segment,
          style: baseStyle.copyWith(
            color: isPlaying ? highlightColor : null,
            backgroundColor: _ayahBackgroundColor(
              ayahNumber: ayahNum,
              controller: controller,
            ),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => controller.onAyahTap(ayahNum),
        ),
      );
      pos = match.end;
      currentAyah++;
    }

    // Any trailing text after the last marker.
    if (pos < arabicText.length) {
      spans.add(TextSpan(text: arabicText.substring(pos), style: baseStyle));
    }

    return spans;
  }

  Widget _buildTranslationBlocks(
    BuildContext context,
    List<TranslationBlockModel> allBlocks,
    int ayaStart,
    int ayaEnd,
    int surahNumber,
    SurahProvider controller,
  ) {
    final fontSettings = Provider.of<FontSizeChangerProvider>(context);
    final isMl = context.read<LanguageProvider>().isMalayalam;
    final matching = allBlocks.where((b) {
      final from = b.verseFrom ?? 0;
      final to = b.verseTo ?? 0;
      return from >= ayaStart && to <= ayaEnd;
    }).toList();

    if (matching.isEmpty) return const SizedBox.shrink();

    // A new paragraph starts whenever the cleaned text begins with a digit
    // (e.g. "1-4 ...", "5. ...", "6,7 ...").
    // Rows without a leading digit are continuations that flow inline with
    // the preceding paragraph.
    final groups = <List<TranslationBlockModel>>[];
    for (final block in matching) {
      final preview = (block.translationText ?? '')
          .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '')
          .trim();
      if (groups.isEmpty || RegExp(r'^\d').hasMatch(preview)) {
        groups.add([block]);
      } else {
        groups.last.add(block);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: groups.map((segments) {
          final spans = <InlineSpan>[];
          for (int i = 0; i < segments.length; i++) {
            final block = segments[i];
            final raw = block.translationText ?? '';
            final cleaned = raw
                .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '')
                .trim();
            final blockAyah = block.verseFrom ?? ayaStart;
            if (i > 0) {
              spans.add(const TextSpan(text: ' '));
            }

            if (block.translationNo != null) {
              // Legacy path: translationNo from old DB column
              spans.addAll(
                _crossRefSpansForPlainText(
                  context,
                  cleaned,
                  AppTextTheme.surahTranslationStyle(
                    context,
                    isMalayalam: isMl,
                  ),
                  surahNumber,
                ),
              );
              final num = block.translationNo!;
              spans.add(
                buildInterpretationNoteMarkerSpan(
                  number: num,
                  onTap: () => _showInterpretationSheet(
                    context,
                    controller,
                    blockAyah,
                    pageNumber: num,
                  ),
                ),
              );
            } else {
              // New DB: split text around every (N) and make each tappable
              final pattern = RegExp(r'\((\d+)\)');
              int lastEnd = 0;
              bool found = false;
              for (final match in pattern.allMatches(cleaned)) {
                found = true;
                if (match.start > lastEnd) {
                  spans.addAll(
                    _crossRefSpansForPlainText(
                      context,
                      cleaned.substring(lastEnd, match.start),
                      AppTextTheme.surahTranslationStyle(
                        context,
                        isMalayalam: isMl,
                      ),
                      surahNumber,
                    ),
                  );
                }
                final num = int.tryParse(match.group(1)!);
                if (num == null) {
                  spans.add(
                    TextSpan(
                      text: match.group(0),
                      style: AppTextTheme.surahTranslationStyle(
                        context,
                        isMalayalam: isMl,
                      ),
                    ),
                  );
                } else {
                  spans.add(
                    buildInterpretationNoteMarkerSpan(
                      number: num,
                      onTap: () => _showInterpretationSheet(
                        context,
                        controller,
                        blockAyah,
                        pageNumber: num,
                      ),
                    ),
                  );
                }
                lastEnd = match.end;
              }
              if (found && lastEnd < cleaned.length) {
                spans.addAll(
                  _crossRefSpansForPlainText(
                    context,
                    cleaned.substring(lastEnd),
                    AppTextTheme.surahTranslationStyle(
                      context,
                      isMalayalam: isMl,
                    ),
                    surahNumber,
                  ),
                );
              }
              if (!found) {
                // Try [^N] pattern for Malayalam footnote markers
                if (isMl) {
                  final mlPattern = RegExp(r'\[\^?(\d+)\]');
                  int mlLastEnd = 0;
                  bool mlFound = false;
                  for (final match in mlPattern.allMatches(cleaned)) {
                    mlFound = true;
                    if (match.start > mlLastEnd) {
                      spans.addAll(
                        _crossRefSpansForPlainText(
                          context,
                          cleaned.substring(mlLastEnd, match.start),
                          AppTextTheme.surahTranslationStyle(
                            context,
                            isMalayalam: isMl,
                          ),
                          surahNumber,
                        ),
                      );
                    }
                    final num = int.tryParse(match.group(1)!);
                    if (num == null) {
                      spans.add(
                        TextSpan(
                          text: match.group(0),
                          style: AppTextTheme.surahTranslationStyle(
                            context,
                            isMalayalam: isMl,
                          ),
                        ),
                      );
                    } else {
                      spans.add(
                        buildInterpretationNoteMarkerSpan(
                          number: num - controller.mlFootnoteMinNumber + 1,
                          onTap: () => _showInterpretationSheet(
                            context,
                            controller,
                            blockAyah,
                            pageNumber: num,
                          ),
                        ),
                      );
                    }
                    mlLastEnd = match.end;
                  }
                  if (mlFound && mlLastEnd < cleaned.length) {
                    spans.addAll(
                      _crossRefSpansForPlainText(
                        context,
                        cleaned.substring(mlLastEnd),
                        AppTextTheme.surahTranslationStyle(
                          context,
                          isMalayalam: isMl,
                        ),
                        surahNumber,
                      ),
                    );
                  }
                  if (!mlFound) {
                    spans.addAll(
                      _crossRefSpansForPlainText(
                        context,
                        cleaned,
                        AppTextTheme.surahTranslationStyle(
                          context,
                          isMalayalam: isMl,
                        ),
                        surahNumber,
                      ),
                    );
                  }
                } else {
                  spans.addAll(
                    _crossRefSpansForPlainText(
                      context,
                      cleaned,
                      AppTextTheme.surahTranslationStyle(
                        context,
                        isMalayalam: isMl,
                      ),
                      surahNumber,
                    ),
                  );
                }
              }
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(children: spans),
              textAlign: resolveTranslationTextAlign(
                isMalayalam: isMl,
                justifyTranslation: fontSettings.translationJustify,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Builds interpretation text with tappable cross-references.
  Widget _buildInterpretationCrossRefText(
    BuildContext context,
    String text,
    int currentSurahNumber,
    bool justify,
  ) {
    final isMalayalam = context.read<LanguageProvider>().isMalayalam;
    final segments = parseForCrossReferences(text, currentSurahNumber);
    // Fast path: no cross-references found
    if (segments.length == 1 && !segments.first.isCrossReference) {
      return Text(
        text,
        style: AppTextTheme.surahInterpretationStyle(
          context,
          isMalayalam: isMalayalam,
        ),
        textAlign: resolveInterpretationTextAlign(
          isMalayalam: isMalayalam,
          justifyInterpretation: justify,
        ),
      );
    }

    final baseStyle = AppTextTheme.surahInterpretationStyle(
      context,
      isMalayalam: isMalayalam,
    );
    final isDarkLink = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDarkLink ? const Color(0xff5B9BD5) : AppTheme.appIconTheme;
    final linkStyle = baseStyle.copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
    );

    final spans = <InlineSpan>[];
    for (final seg in segments) {
      if (seg.isCrossReference) {
        final ref = seg.crossReference!;
        spans.add(
          TextSpan(
            text: seg.text,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  CrossReferenceSheet.handleReferenceTap(context, ref),
          ),
        );
      } else {
        spans.add(TextSpan(text: seg.text, style: baseStyle));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: resolveInterpretationTextAlign(
        isMalayalam: isMalayalam,
        justifyInterpretation: justify,
      ),
    );
  }

  /// Takes plain text and a [TextStyle] and returns a list of [InlineSpan]s
  /// where any detected cross-references (e.g. "57:20") are tappable.
  /// If no cross-references are found, returns a single [TextSpan].
  List<InlineSpan> _crossRefSpansForPlainText(
    BuildContext context,
    String text,
    TextStyle style,
    int currentSurahNumber,
  ) {
    final segments = parseForCrossReferences(text, currentSurahNumber);
    if (segments.length == 1 && !segments.first.isCrossReference) {
      return [TextSpan(text: text, style: style)];
    }

    final isDarkRef = Theme.of(context).brightness == Brightness.dark;
    final refLinkColor = isDarkRef ? const Color(0xff5B9BD5) : AppTheme.appIconTheme;
    final linkStyle = style.copyWith(
      color: refLinkColor,
      decoration: TextDecoration.underline,
      decorationColor: refLinkColor,
    );

    return segments.map<InlineSpan>((seg) {
      if (seg.isCrossReference) {
        final ref = seg.crossReference!;
        return TextSpan(
          text: seg.text,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () =>
                CrossReferenceSheet.handleReferenceTap(context, ref),
        );
      }
      return TextSpan(text: seg.text, style: style);
    }).toList();
  }

  void _showInterpretationSheet(
    BuildContext context,
    SurahProvider controller,
    int ayahNumber, {
    int? pageNumber,
  }) {
    if (pageNumber != null) {
      controller.getInterpretationsForPage(pageNumber);
    } else {
      controller.getInterpretationsForAyah(ayahNumber);
    }
    final size = MediaQuery.sizeOf(context);
    const double maxDialogWidth = 620;
    final double hInset = size.width < 640
        ? 12.0
        : ((size.width - maxDialogWidth) / 2).clamp(24.0, double.infinity);
    final double maxHeight = (size.height * 0.85).clamp(300.0, 760.0);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: kInterpretationSheetBarrierColor,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: hInset, vertical: 24),
        child: Consumer<SurahProvider>(
          builder: (ctx, ctrl, _) {
            final theme = Theme.of(ctx);
            final isDark = theme.brightness == Brightness.dark;
            final panelColor = isDark ? theme.cardColor : Colors.white;
            final borderColor = isDark
                ? Colors.white.withValues(alpha: 0.12)
                : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant);
            final fontSettings = Provider.of<FontSizeChangerProvider>(ctx);
            final isMalayalam = ctx.watch<LanguageProvider>().isMalayalam;
            final isLoading = ctrl.currentInterpretationNumber == -1;
            final hasBounds =
                ctrl.minInterpretationNumber != -1 &&
                ctrl.maxInterpretationNumber != -1;
            final canPrev =
                hasBounds &&
                ctrl.currentInterpretationNumber > ctrl.minInterpretationNumber;
            final canNext =
                hasBounds &&
                ctrl.currentInterpretationNumber < ctrl.maxInterpretationNumber;
            final hasSurah =
                ctrl.surahList.isNotEmpty &&
                ctrl.index >= 0 &&
                ctrl.index < ctrl.surahList.length;
            final surah = hasSurah ? ctrl.surahList[ctrl.index] : null;
            final headerSurahNumber = surah?.surahNumber ?? (ctrl.index + 1);
            final headerInterpretationNumber =
                ctrl.currentInterpretationNumber > 0
                ? ctrl.currentInterpretationNumber
                : (pageNumber ?? -1);
            final displayInterpretationNumber = isMalayalam
                ? headerInterpretationNumber - ctrl.mlFootnoteMinNumber + 1
                : headerInterpretationNumber;
            final surahHeader = formatInterpretationSheetSurahHeader(
              isMalayalam: isMalayalam,
              surah: surah,
            );
            final metadataLabel = headerInterpretationNumber > 0
                ? formatInterpretationMetadataLabel(
                    isMalayalam: isMalayalam,
                    surahNumber: headerSurahNumber,
                    interpretationNumber: displayInterpretationNumber,
                    ayahNumbers: ctrl.currentInterpretationAyahNumbers,
                  )
                : (isMalayalam
                      ? 'സൂറത്ത് $headerSurahNumber'
                      : 'Surah $headerSurahNumber');

            String combinedText() {
              final body = ctrl.interpretationList
                  .map((e) => e.interpretationText)
                  .join('\n\n');
              final headerLines = <String>[
                ...surahHeader.toLines(),
                if (metadataLabel.trim().isNotEmpty) metadataLabel,
              ];
              final headerText = headerLines.join('\n').trim();
              if (headerText.isEmpty) return body;
              return body.trim().isEmpty ? headerText : '$headerText\n\n$body';
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxDialogWidth,
                  maxHeight: maxHeight,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      InterpretationSheetHeader(
                        surahHeader: surahHeader,
                        metadataLabel: metadataLabel,
                        onClose: () => Navigator.of(ctx).pop(),
                        padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                        closeButtonOffset: Offset.zero,
                        titleSpacing: 0,
                        compactCloseButton: true,
                      ),
                      const Divider(height: 1),
                      // Content
                      Flexible(
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: SingleChildScrollView(
                                  key: ValueKey(ctrl.currentInterpretationNumber),
                                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: ctrl.interpretationList.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: _buildInterpretationCrossRefText(
                                          ctx,
                                          item.interpretationText,
                                          ctrl.surahList.isNotEmpty
                                              ? ctrl.surahList[ctrl.index].surahNumber
                                              : 0,
                                          fontSettings.interpretationJustify,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                      ),
                      // Bottom bar: prev | page counter | next | copy | share
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        child: Builder(
                          builder: (barCtx) {
                            final isDarkBar =
                                Theme.of(barCtx).brightness == Brightness.dark;
                            final activeColor =
                                isDarkBar ? Colors.white : Colors.black;
                            return Row(
                              children: [
                                IconButton(
                                  tooltip: 'Previous',
                                  onPressed: canPrev
                                      ? () => ctrl.navigateInterpretation(false)
                                      : null,
                                  icon: Icon(
                                    Icons.chevron_left,
                                    color: canPrev
                                        ? activeColor
                                        : Colors.grey[400],
                                  ),
                                ),
                                if (!isLoading && hasBounds)
                                  Text(
                                    isMalayalam
                                        ? '${ctrl.currentInterpretationNumber - ctrl.mlFootnoteMinNumber + 1} / ${ctrl.maxInterpretationNumber - ctrl.mlFootnoteMinNumber + 1}'
                                        : '${ctrl.currentInterpretationNumber} / ${ctrl.maxInterpretationNumber}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: activeColor,
                                    ),
                                  ),
                                IconButton(
                                  tooltip: 'Next',
                                  onPressed: canNext
                                      ? () => ctrl.navigateInterpretation(true)
                                      : null,
                                  icon: Icon(
                                    Icons.chevron_right,
                                    color: canNext
                                        ? activeColor
                                        : Colors.grey[400],
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Copy',
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          final text = combinedText();
                                          if (text.trim().isNotEmpty) {
                                            await Clipboard.setData(
                                              ClipboardData(text: text),
                                            );
                                            if (ctx.mounted) {
                                              ScaffoldMessenger.of(ctx)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Copied to clipboard'),
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  icon: Icon(
                                    Icons.copy_outlined,
                                    color: isLoading
                                        ? Colors.grey[400]
                                        : activeColor,
                                  ),
                                ),
                                Builder(
                                  builder: (shareButtonContext) => IconButton(
                                    tooltip: 'Share',
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                            final text = combinedText();
                                            if (text.trim().isNotEmpty) {
                                              await Share.share(
                                                text,
                                                sharePositionOrigin:
                                                    _sharePositionOriginFor(
                                                  shareButtonContext,
                                                ),
                                              );
                                            }
                                          },
                                    icon: Icon(
                                      Icons.share_outlined,
                                      color: isLoading
                                          ? Colors.grey[400]
                                          : activeColor,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SurahProvider>(context);
    final useDesktopWebReaderLayout = _useDesktopWebReaderLayout(context);
    final useCompactWebReaderLayout = _useCompactWebReaderLayout(context);
    const readerBottomClearance = 28.0;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _saveLastRead();
          Provider.of<AudioProvider>(context, listen: false).stopAudio();
        }
      },
      child: BaseScreenLayout(
        topBorderRadius: kIsWeb
            ? AppTheme.desktopContentCardRadius
            : 40,
        bottomBorderRadius: kIsWeb
            ? AppTheme.desktopContentCardRadius
            : 0,
        appBar: CommonAppBar.appBar(
          context,
          showBrandLogo: true,
          showSearch: false,
          titleWidget: _buildSurahAppBarTitleControls(controller),
          actions: kIsWeb
              ? [_buildSurahWebActions(context)]
              : null,
        ),
        headerContent: useDesktopWebReaderLayout
            ? _buildDesktopReaderHeader(context, controller)
            : null,
        drawer: const CommonDrawer(),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScrollToTopButton(
              visible: _showScrollToTop,
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (controller.ayahTapHandled) {
                    controller.ayahTapHandled = false;
                    return;
                  }
                  if (controller.isSelectionActive) {
                    controller.clearSelection();
                  }
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: controller.arabicBlockList.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : Builder(
                              builder: (_) {
                                final surahNumber =
                                    controller.surahList.isNotEmpty
                                    ? controller
                                          .surahList[controller.index]
                                          .surahNumber
                                    : 0;
                                final showDecorativeBismillah =
                                  surahNumber > 0 &&
                                  surahNumber != 1 &&
                                  surahNumber != 9;
                                final surahName =
                                    controller.surahList.isNotEmpty
                                    ? controller
                                          .surahList[controller.index]
                                          .name
                                    : 'Surah';
                                final hPad = ResponsiveHelper.horizontalPadding(
                                  context,
                                );
                                final content = Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    hPad,
                                    0,
                                    hPad,
                                    0,
                                  ),
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey(controller.index),
                                    tween: Tween(
                                      begin: widget.scrollToAyahId != null
                                          ? 1.0
                                          : 0.0,
                                      end: 1.0,
                                    ),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                    builder: (context, opacity, child) {
                                      return Opacity(
                                        opacity: opacity,
                                        child: child,
                                      );
                                    },
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onHorizontalDragEnd:
                                          _handleContinuousModeSwipe,
                                      child: ResponsiveContentWrapper(
                                        child: PinchZoomView(
                                          child: CustomScrollView(
                                              controller: _scrollController,
                                              cacheExtent: _deepLinkCacheExtent,
                                              slivers: [
                                                if (useCompactWebReaderLayout)
                                                  SliverToBoxAdapter(
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(bottom: 12),
                                                      child: _buildDesktopReaderHeader(
                                                        context,
                                                        controller,
                                                      ),
                                                    ),
                                                  )
                                                else if (!useDesktopWebReaderLayout)
                                                  SurahScreenAppBar(
                                                    arabicBlockList: controller.arabicBlockList,
                                                    currentAyahNumber:
                                                        _lastKnownAyahStart ??
                                                        (controller.arabicBlockList.firstOrNull
                                                                ?.verseFrom ??
                                                            1),
                                                    onAyahSelected: _jumpToAyah,
                                                    onPlayPressed:
                                                        _restartSurahPlayback,
                                                    onInfoPressed: _hasPreface
                                                        ? () => _showSurahInfo(
                                                              context,
                                                              controller,
                                                            )
                                                        : null,
                                                  )
                                                else
                                                  const SliverToBoxAdapter(
                                                    child: SizedBox(height: 12),
                                                  ),
                                                if (showDecorativeBismillah)
                                                  SliverToBoxAdapter(
                                                    child: _SurahBismillahHeader(
                                                      glyphText: controller
                                                          .currentBismillahGlyph,
                                                    ),
                                                  ),
                                              SliverList(
                                                delegate: SliverChildBuilderDelegate(
                                                  (context, index) {
                                                    final block = controller
                                                        .arabicBlockList[index];
                                                    final ayaStart =
                                                        block.verseFrom ??
                                                        index + 1;
                                                    final ayaEnd =
                                                        block.verseTo ??
                                                        index + 1;
                                                    final arabicText =
                                                        block.arabicText ?? '';
                                                    final ayaStartText =
                                                        ayaStart.toString();
                                                    final ayaEndText = ayaEnd
                                                        .toString();
                                                    final isLastBlock =
                                                        index ==
                                                        controller
                                                                .arabicBlockList
                                                                .length -
                                                            1;
                                                    final ayahRange =
                                                        ayaStart == ayaEnd
                                                        ? 'Ayah $ayaStartText'
                                                        : 'Ayahs $ayaStartText to $ayaEndText';

                                                    return Semantics(
                                                      label:
                                                          '$surahName, $ayahRange',
                                                      child: Consumer<AudioProvider>(
                                                        key: _itemKeys[index],
                                                        builder: (highlightCtx, audio, _) {
                                                          final effectivePlayingAyahId =
                                                              audio.isActive &&
                                                                  surahNumber >
                                                                      0 &&
                                                                  audio.currentSurahNumber ==
                                                                      surahNumber
                                                              ? audio
                                                                    .playingAyahId
                                                              : null;
                                                          return Padding(
                                                            key: ValueKey(
                                                              index,
                                                            ),
                                                            padding:
                                                                const EdgeInsets.fromLTRB(
                                                                  4,
                                                                  8,
                                                                  4,
                                                                  4,
                                                                ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                if (arabicText
                                                                    .isNotEmpty)
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets.only(
                                                                          bottom:
                                                                              8.0,
                                                                        ),
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .stretch,
                                                                      children: [
                                                                        Consumer<
                                                                          TajweedProvider
                                                                        >(
                                                                          builder:
                                                                              (
                                                                                ctx,
                                                                                tajweed,
                                                                                _,
                                                                              ) {
                                                                                final quranJustify =
                                                                                    Provider.of<
                                                                                          FontSizeChangerProvider
                                                                                        >(
                                                                                          ctx,
                                                                                        )
                                                                                        .quranJustify;
                                                                                if (tajweed.enabled) {
                                                                                  return _TajweedHtmlText(
                                                                                    surahNo: surahNumber,
                                                                                    verseFrom: ayaStart,
                                                                                    verseTo: ayaEnd,
                                                                                    playingAyahId: effectivePlayingAyahId,
                                                                                  );
                                                                                }
                                                                                return Text.rich(
                                                                                  TextSpan(
                                                                                    children: _buildArabicSpans(
                                                                                      arabicText,
                                                                                      ayaStart,
                                                                                      effectivePlayingAyahId,
                                                                                      AppTextTheme.surahArabiStyle(
                                                                                        context,
                                                                                      ),
                                                                                      AppTheme.appIconTheme,
                                                                                      controller,
                                                                                    ),
                                                                                  ),
                                                                                  textHeightBehavior: const TextHeightBehavior(
                                                                                    applyHeightToFirstAscent: false,
                                                                                    applyHeightToLastDescent: false,
                                                                                  ),
                                                                                  textDirection: TextDirection.rtl,
                                                                                  textAlign: quranJustify
                                                                                      ? TextAlign.justify
                                                                                      : TextAlign.start,
                                                                                );
                                                                              },
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              10,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ShowTranslationGate(
                                                                  hasTranslation:
                                                                      controller
                                                                          .translationBlockList
                                                                          .isNotEmpty,
                                                                  builder:
                                                                      (context) =>
                                                                          _buildTranslationBlocks(
                                                                            context,
                                                                            controller.translationBlockList,
                                                                            ayaStart,
                                                                            ayaEnd,
                                                                            surahNumber,
                                                                            controller,
                                                                          ),
                                                                ),
                                                                Builder(
                                                                  builder: (context) {
                                                                    final isBookmarked =
                                                                        controller.isAyahBookmarked(
                                                                          surahNumber,
                                                                          ayaStart,
                                                                        );
                                                                    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                                                                    final actionIconColor = isDarkMode
                                                                        ? Colors.white.withValues(alpha: 0.7)
                                                                        : AppTheme.appIconTheme;
                                                                    return Row(
                                                                      children: [
                                                                        Consumer<
                                                                          AudioProvider
                                                                        >(
                                                                          builder:
                                                                              (
                                                                                ctx,
                                                                                audio,
                                                                                _,
                                                                              ) {
                                                                                final isThis = audio.isCurrentAyah(
                                                                                  surahNumber,
                                                                                  ayaStart,
                                                                                );
                                                                                final isLoadingThis =
                                                                                    audio.isLoading &&
                                                                                    isThis;
                                                                                return IconButton(
                                                                                  tooltip: isThis
                                                                                      ? 'Stop'
                                                                                      : 'Play',
                                                                                  onPressed: () {
                                                                                    if (isThis) {
                                                                                      audio.stopAudio();
                                                                                    } else {
                                                                                      final ps =
                                                                                          Provider.of<
                                                                                            PlaySettingsProvider
                                                                                          >(
                                                                                            ctx,
                                                                                            listen: false,
                                                                                          );
                                                                                      audio.playAyah(
                                                                                        surahNumber: surahNumber,
                                                                                        ayahId: ayaStart,
                                                                                        ayahEndId: ayaEnd,
                                                                                        translationIndex: index,
                                                                                        reciter: ps.selectedReciter,
                                                                                        playbackSpeed: ps.playbackSpeed,
                                                                                      );
                                                                                    }
                                                                                  },
                                                                                  icon: isLoadingThis
                                                                                      ? SizedBox(
                                                                                          width: 20,
                                                                                          height: 20,
                                                                                          child: CircularProgressIndicator(
                                                                                            strokeWidth: 2,
                                                                                            color: actionIconColor,
                                                                                          ),
                                                                                        )
                                                                                      : Icon(
                                                                                          isThis
                                                                                              ? Icons.stop_circle
                                                                                              : Icons.play_circle_outline,
                                                                                          color: actionIconColor,
                                                                                        ),
                                                                                );
                                                                              },
                                                                        ),
                                                                        IconButton(
                                                                          tooltip:
                                                                              isBookmarked
                                                                              ? 'Remove bookmark'
                                                                              : 'Bookmark',
                                                                          onPressed: () => _toggleSurahBookmark(
                                                                            context:
                                                                                context,
                                                                            controller:
                                                                                controller,
                                                                            surahNumber:
                                                                                surahNumber,
                                                                            ayahId:
                                                                                ayaStart,
                                                                            isBookmarked:
                                                                                isBookmarked,
                                                                            ayaText:
                                                                                arabicText.isNotEmpty
                                                                                ? arabicText
                                                                                : null,
                                                                          ),
                                                                          icon: Icon(
                                                                            isBookmarked
                                                                                ? Icons.bookmark
                                                                                : Icons.bookmark_border,
                                                                            color: isBookmarked
                                                                                ? actionIconColor
                                                                                : actionIconColor,
                                                                          ),
                                                                        ),
                                                                        Builder(
                                                                          builder:
                                                                              (
                                                                                shareButtonContext,
                                                                              ) =>
                                                                                  IconButton(
                                                                                    tooltip:
                                                                                        'Share',
                                                                                    onPressed: () async {
                                                                                      final shareText =
                                                                                          controller.getAyahText(
                                                                                            ayaStart,
                                                                                          );
                                                                                      if (shareText.trim().isNotEmpty) {
                                                                                        await Share.share(
                                                                                          shareText,
                                                                                          sharePositionOrigin:
                                                                                              _sharePositionOriginFor(
                                                                                                shareButtonContext,
                                                                                              ),
                                                                                        );
                                                                                      }
                                                                                    },
                                                                                    icon: Icon(
                                                                                      Icons.share_outlined,
                                                                                      color:
                                                                                          actionIconColor,
                                                                                    ),
                                                                                  ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                ),
                                                                if (isLastBlock)
                                                                  _buildFinalAyahNavSection(
                                                                    context,
                                                                  )
                                                                else
                                                                  const Divider(
                                                                    thickness:
                                                                        0.5,
                                                                  ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  childCount: controller
                                                      .arabicBlockList
                                                      .length,
                                                ),
                                              ),
                                              const SliverToBoxAdapter(
                                                child: SizedBox(
                                                  height: readerBottomClearance,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );

                                return content;
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sticky mini-player bar ────────────────────────────
            Consumer<AudioProvider>(
              builder: (context, audio, _) {
                if (!audio.isActive) return const SizedBox.shrink();
                final surahProv = Provider.of<SurahProvider>(
                  context,
                  listen: false,
                );
                final playSettings = Provider.of<PlaySettingsProvider>(
                  context,
                  listen: false,
                );
                // Find the PLAYING surah by its number, not by the viewed index.
                final playingSurah = audio.currentSurahNumber != null
                    ? surahProv.surahList.cast<dynamic>().firstWhere(
                        (s) => s.surahNumber == audio.currentSurahNumber,
                        orElse: () => null,
                      )
                    : null;
                final surahName = playingSurah?.name ?? '';
                final ayahLabel = audio.playingAyahId != null
                    ? 'Ayah ${audio.playingAyahId!}'
                    : '';
                final translationIdx = audio.currentTranslationIndex;
                final canPrev = translationIdx != null && translationIdx > 0;
                // canNext: only meaningful when the viewed surah is the playing
                // surah (so translationList belongs to the playing surah).
                final isViewingPlayingSurah =
                    surahProv.surahList.isNotEmpty &&
                    surahProv.index < surahProv.surahList.length &&
                    surahProv.surahList[surahProv.index].surahNumber ==
                        audio.currentSurahNumber;
                final canNext =
                    isViewingPlayingSurah &&
                    translationIdx != null &&
                    translationIdx < surahProv.arabicBlockList.length - 1;

                return Semantics(
                  liveRegion: true,
                  label:
                      'Audio player: $surahName, $ayahLabel, ${audio.isPlaying ? 'playing' : 'paused'}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade900
                          : Colors.grey.shade100,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  surahName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  ayahLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          // Previous
                          IconButton(
                            tooltip: 'Previous',
                            onPressed: canPrev
                                ? () {
                                    final prevIdx = translationIdx - 1;
                                    final blocks = surahProv.arabicBlockList;
                                    final prevStart =
                                        blocks[prevIdx].verseFrom ??
                                        prevIdx + 1;
                                    final prevEnd =
                                        blocks[prevIdx].verseTo ?? prevStart;
                                    audio.playAyah(
                                      surahNumber:
                                          surahProv.surahList.isNotEmpty
                                          ? surahProv
                                                .surahList[surahProv.index]
                                                .surahNumber
                                          : 0,
                                      ayahId: prevStart,
                                      ayahEndId: prevEnd,
                                      translationIndex: prevIdx,
                                      reciter: playSettings.selectedReciter,
                                      playbackSpeed: playSettings.playbackSpeed,
                                    );
                                  }
                                : null,
                            icon: const Icon(
                              Icons.skip_previous,
                              color: AppTheme.appIconTheme,
                            ),
                          ),
                          // Play / Pause
                          IconButton(
                            tooltip: audio.isPlaying ? 'Pause' : 'Resume',
                            onPressed: () => audio.togglePlayPause(),
                            icon: Icon(
                              audio.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppTheme.appIconTheme,
                            ),
                          ),
                          // Stop
                          IconButton(
                            tooltip: 'Stop',
                            onPressed: () => audio.stopAudio(),
                            icon: const Icon(
                              Icons.stop,
                              color: AppTheme.appIconTheme,
                            ),
                          ),
                          // Next
                          IconButton(
                            tooltip: 'Next',
                            onPressed: canNext
                                ? () {
                                    final nextIdx = translationIdx + 1;
                                    final blocks = surahProv.arabicBlockList;
                                    final nextStart =
                                        blocks[nextIdx].verseFrom ??
                                        nextIdx + 1;
                                    final nextEnd =
                                        blocks[nextIdx].verseTo ?? nextStart;
                                    audio.playAyah(
                                      surahNumber:
                                          surahProv.surahList.isNotEmpty
                                          ? surahProv
                                                .surahList[surahProv.index]
                                                .surahNumber
                                          : 0,
                                      ayahId: nextStart,
                                      ayahEndId: nextEnd,
                                      translationIndex: nextIdx,
                                      reciter: playSettings.selectedReciter,
                                      playbackSpeed: playSettings.playbackSpeed,
                                    );
                                  }
                                : null,
                            icon: const Icon(
                              Icons.skip_next,
                              color: AppTheme.appIconTheme,
                            ),
                          ),
                          // Speed
                          Consumer<PlaySettingsProvider>(
                            builder: (_, speedPS, _) => TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(40, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () {
                                final newSpeed = speedPS.cycleSpeed();
                                audio.setSpeed(newSpeed);
                              },
                              child: Text(
                                '${speedPS.playbackSpeed}x',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Close mini-player
                          IconButton(
                            tooltip: 'Close player',
                            onPressed: () => audio.stopAudio(),
                            icon: const Icon(
                              Icons.close,
                              color: AppTheme.appIconTheme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Selection action bar ──────────────────────────────
            if (controller.isSelectionActive)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF338FCC),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.selectionLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final text = controller.getSelectedText();
                          if (text.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                          controller.clearSelection();
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Clear selection',
                        onPressed: () => controller.clearSelection(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tajweed coloured-HTML text (bundled quran.com data) ──────────────────────

class _TajweedHtmlText extends StatefulWidget {
  const _TajweedHtmlText({
    required this.surahNo,
    required this.verseFrom,
    required this.verseTo,
    this.playingAyahId,
  });

  final int surahNo;
  final int verseFrom;
  final int verseTo;
  final int? playingAyahId;

  @override
  State<_TajweedHtmlText> createState() => _TajweedHtmlTextState();
}

class _TajweedHtmlTextState extends State<_TajweedHtmlText> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    TajweedHtmlService.ensureLoaded().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontProvider = Provider.of<FontSizeChangerProvider>(context);
    final quranJustify = fontProvider.quranJustify;
    final baseStyle = AppTextTheme.tajweedArabiStyle(context);
    // Ayah-end marker keeps the standard reading font; QuranTaha renders the
    // ﴿﴾ ornamental parentheses as oversized decorative glyphs.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markerStyle = AppTextTheme.surahArabiStyle(context).copyWith(
      color: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
    );

    if (!_loaded) {
      return SizedBox(
        height: baseStyle.fontSize ?? 22,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final spans = <InlineSpan>[];
    for (var ayah = widget.verseFrom; ayah <= widget.verseTo; ayah++) {
      final html = TajweedHtmlService.displayHtmlFor(widget.surahNo, ayah);
      if (html == null) continue;
      final isPlaying = widget.playingAyahId == ayah;
      final ayahStyle = isPlaying
          ? baseStyle.copyWith(backgroundColor: AppTheme.appIconTheme.withValues(alpha: 0.15))
          : baseStyle;
      spans.addAll(parseTajweedHtml(html, ayahStyle));
      // Ayah-end marker, matching the Arabic ornamental parentheses used in the
      // normal Arabic view (U+FD3F ﴿ ... U+FD3E ﴾).
      spans.add(
        TextSpan(
          text: ' \uFD3F${_toArabicNumerals(ayah)}\uFD3E ',
          style: markerStyle,
        ),
      );
    }

    if (spans.isEmpty) return const SizedBox.shrink();

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: quranJustify ? TextAlign.justify : TextAlign.start,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
  }
}

// ── Tajweed word-image row ────────────────────────────────────────────────────
// NOTE: Currently unused. The Tajweed feature now renders via _TajweedHtmlText
// (bundled colour-coded data). Kept temporarily; may be removed later.

class _TajweedWordRow extends StatefulWidget {
  const _TajweedWordRow({
    required this.surahNo,
    required this.verseFrom,
    required this.verseTo,
    // ignore: unused_element_parameter
    this.playingAyahId,
  });

  final int surahNo;
  final int verseFrom;
  final int verseTo;
  final int? playingAyahId;

  @override
  State<_TajweedWordRow> createState() => _TajweedWordRowState();
}

class _TajweedWordRowState extends State<_TajweedWordRow> {
  List<TajweedWordModel>? _words;
  String? _imagesDir;
  // Tracks which ayah numbers have their last word image fully loaded.
  final Map<int, bool> _ayahBadgeVisible = {};

  @override
  void initState() {
    super.initState();
    _initImagesDir();
    _loadWords();
  }

  Future<void> _initImagesDir() async {
    final dir = await TajweedProvider.imagesDirPath;
    if (mounted) setState(() => _imagesDir = dir);
  }

  @override
  void didUpdateWidget(_TajweedWordRow old) {
    super.didUpdateWidget(old);
    if (old.surahNo != widget.surahNo ||
        old.verseFrom != widget.verseFrom ||
        old.verseTo != widget.verseTo) {
      _loadWords();
    }
  }

  Future<void> _loadWords() async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return;
    final words = await TajweedDbHelper.getWordsForBlock(
      db: db,
      surahNo: widget.surahNo,
      verseFrom: widget.verseFrom,
      verseTo: widget.verseTo,
    );
    if (mounted) {
      setState(() {
        _ayahBadgeVisible.clear();
        _words = words;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontProvider = Provider.of<FontSizeChangerProvider>(context);
    final quranJustify = fontProvider.quranJustify;
    // Scale the tajweed word images to the user's Qur'an font size so they
    // track the "Qur'an Font Size" setting like the plain Arabic text does.
    // 40px was the original fixed height tuned for the default size of 22.
    final imageHeight = fontProvider.quranFontSize * (40 / 22);
    final words = _words;
    if (words == null) {
      return SizedBox(
        height: imageHeight,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (words.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group words by ayah number so we can insert an ayah-number badge
    // after the last word of each ayah — matching the normal Arabic text view.
    final Map<int, List<TajweedWordModel>> byAyah = {};
    for (final w in words) {
      byAyah.putIfAbsent(w.ayahNo, () => []).add(w);
    }
    final sortedAyahs = byAyah.keys.toList()..sort();

    final playingAyah = widget.playingAyahId;

    final children = <Widget>[];
    for (final ayahNo in sortedAyahs) {
      final isPlayingAyah = playingAyah != null && ayahNo == playingAyah;
      final ayahWords = byAyah[ayahNo]!;
      for (var i = 0; i < ayahWords.length; i++) {
        final w = ayahWords[i];
        final isLast = i == ayahWords.length - 1;
        // IntrinsicWidth breaks the tight width constraint that PageView
        // propagates down, so each image sizes to its natural aspect-ratio
        // width rather than expanding to fill the full page width.
        final localPath = _imagesDir != null
            ? TajweedProvider.localPathFor(_imagesDir!, w.imageUrl)
            : null;
        final wordWidget = IntrinsicWidth(
          child: localPath != null
              ? Image.file(
                  File(localPath),
                  height: imageHeight,
                  fit: BoxFit.fitHeight,
                  frameBuilder: isLast
                      ? (ctx, child, frame, wasSynchronouslyLoaded) {
                          if (frame != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted &&
                                  _ayahBadgeVisible[ayahNo] != true) {
                                setState(
                                  () => _ayahBadgeVisible[ayahNo] = true,
                                );
                              }
                            });
                          }
                          return child;
                        }
                      : null,
                  errorBuilder: (_, _, _) => Text(
                    w.wordText,
                    textDirection: TextDirection.rtl,
                    textAlign: quranJustify
                        ? TextAlign.justify
                        : TextAlign.start,
                    style: AppTextTheme.surahArabiStyle(context),
                  ),
                )
              : Text(
                  w.wordText,
                  textDirection: TextDirection.rtl,
                  textAlign: quranJustify ? TextAlign.justify : TextAlign.start,
                  style: AppTextTheme.surahArabiStyle(context),
                ),
        );
        children.add(
          isPlayingAyah
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.appIconTheme.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: wordWidget,
                )
              : wordWidget,
        );
      }
      // Badge only appears once the last word image of this ayah has loaded.
      if (_ayahBadgeVisible[ayahNo] == true) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _AyahNumberBadge(number: ayahNo, highlighted: isPlayingAyah),
          ),
        );
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final wrap = Wrap(
      textDirection: TextDirection.rtl,
      alignment: quranJustify
          ? WrapAlignment.spaceBetween
          : WrapAlignment.start,
      spacing: 4,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );

    if (!isDark) return wrap;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: wrap,
      ),
    );
  }
}

/// Circular ayah-number badge matching the style used in normal Arabic view.
class _AyahNumberBadge extends StatelessWidget {
  const _AyahNumberBadge({required this.number, this.highlighted = false});
  final int number;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    // U+FD3F ﴿ and U+FD3E ﴾ are the Arabic ornamental parentheses that
    // bracket ayah numbers — exactly matching the reference image style.
    // TextDirection.ltr prevents the bidi algorithm from mirroring the glyphs.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badge = Text(
      '\uFD3F${_toArabicNumerals(number)}\uFD3E',
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontFamily: 'Scheherazade',
        fontSize: 20,
        color: highlighted
            ? AppTheme.appIconTheme
            : (isDark ? Colors.white : Theme.of(context).colorScheme.primary),
        height: 1,
      ),
    );
    if (!highlighted) return badge;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.appIconTheme.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: badge,
    );
  }
}
