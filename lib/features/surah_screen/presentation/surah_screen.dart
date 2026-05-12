import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/models/tajweed_word_model.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/preface_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/tajweed_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/responsive_content_wrapper.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/core/widgets/scroll_to_top_button.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/surah_screen_app_bar.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/tajweed_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/reading_progress_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/audio_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

bool _isMeccan(String place) =>
    place.contains('مكية') || place.toLowerCase().contains('mecca');

String _toArabicNumerals(int value) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value
      .toString()
      .split('')
      .map((digit) => arabicDigits[int.parse(digit)])
      .join();
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

  /// True while [_advanceToNextSurah] is transitioning to the next surah.
  /// Prevents [didChangeDependencies] from stopping audio during auto-advance.
  bool _isAutoAdvancing = false;

  /// Whether the current surah has a preface in the database.
  bool _hasPreface = false;

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
      if (!_isAutoAdvancing) {
        Provider.of<AudioProvider>(context, listen: false).stopAudio();
      }
      _lastKnownAyahStart = null;
      _lastVisibleAyahEnd = null;
      _lastScrolledPlayingAyahId = null;
      _surahTransitionPending = false;
      _checkPrefaceAvailability();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
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
    final prefaces = await PrefaceDbHelper.getPrefaceBySurahId(surahNumber, malayalam: isMl);
    if (!mounted) return;
    setState(() {
      _hasPreface = prefaces.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
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
              reciterFolder: playSettings.selectedReciter.folderName,
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

      // Scroll to the bookmarked / last-read ayah after the list has been
      // built and laid out. One post-frame callback is enough when the data
      // was pre-loaded; the retry loop inside _scrollToBookmarkedAyah handles
      // any remaining layout latency.
      if (widget.scrollToAyahId != null && mounted) {
        final blocks = surahProv.arabicBlockList;
        var targetIdx = blocks.indexWhere(
          (block) => block.verseFrom == widget.scrollToAyahId,
        );
        // Fallback: find the block whose range contains the ayah
        if (targetIdx < 0) {
          targetIdx = blocks.indexWhere((block) {
            final start = block.verseFrom ?? 0;
            final end = block.verseTo ?? 0;
            return start <= widget.scrollToAyahId! &&
                widget.scrollToAyahId! <= end;
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToBookmarkedAyah(widget.scrollToAyahId!);
        });
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
    // Update scroll-to-top visibility.
    if (_scrollController.hasClients) {
      final show = _scrollController.offset > 200;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    }

    // Track the first fully-visible ayah and the last visible ayah.
    final blocks = _surahProv.arabicBlockList;
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

    _isAutoAdvancing = true;
    // Navigate to the next surah (onSwipe(false) increments the index).
    await surahProv.onSwipe(false);

    final blocks = surahProv.arabicBlockList;
    if (blocks.isEmpty) {
      _isAutoAdvancing = false;
      return;
    }

    final newSurahNumber =
        surahProv.surahList[surahProv.index].surahNumber;
    final firstBlock = blocks[0];
    final ayaStart = firstBlock.verseFrom ?? 1;
    final ayaEnd = firstBlock.verseTo ?? ayaStart;

    audioProv.playAyah(
      surahNumber: newSurahNumber,
      ayahId: ayaStart,
      ayahEndId: ayaEnd,
      translationIndex: 0,
      reciterFolder: playSettings.selectedReciter.folderName,
      playbackSpeed: playSettings.playbackSpeed,
    );
    _isAutoAdvancing = false;
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _listeningAudioProv?.removeListener(_onAudioProviderChanged);
    _listeningAudioProv?.stopAudio();
    super.dispose();
  }

  /// Scrolls to the translation row whose ayaStart matches [ayaStart].
  /// Retries on subsequent frames (up to [_maxScrollRetries]) until the
  /// key's render context becomes available.
  static const int _maxScrollRetries = 20;

  void _scrollToBookmarkedAyah(int ayaStart, {int attempt = 0}) {
    if (attempt >= _maxScrollRetries) return;

    final blocks = Provider.of<SurahProvider>(
      context,
      listen: false,
    ).arabicBlockList;
    var idx = blocks.indexWhere((block) => block.verseFrom == ayaStart);
    // Fallback: find the block whose range contains the ayah
    if (idx < 0) {
      idx = blocks.indexWhere((block) {
        final start = block.verseFrom ?? 0;
        final end = block.verseTo ?? 0;
        return start <= ayaStart && ayaStart <= end;
      });
    }

    // Block data or keys not ready yet — retry.
    if (idx < 0 || idx >= _itemKeys.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBookmarkedAyah(ayaStart, attempt: attempt + 1);
      });
      return;
    }

    final key = _itemKeys[idx];
    if (key.currentContext != null) {
      // Item is in the render tree — scroll precisely to it.
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      // Item is outside the viewport and not mounted yet.
      // Do a rough proportional jump to pull the item into the render tree,
      // then retry ensureVisible on the next frame.
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        if (maxExtent > 0) {
          final fraction = idx / blocks.length;
          _scrollController.jumpTo((fraction * maxExtent).clamp(0, maxExtent));
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBookmarkedAyah(ayaStart, attempt: attempt + 1);
      });
    }
  }

  void _showJumpTo(
    BuildContext context,
    List<ArabicBlockModel> arabicBlockList,
  ) {
    final bsMaxWidth = ResponsiveHelper.bottomSheetMaxWidth(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: bsMaxWidth != null
          ? BoxConstraints(maxWidth: bsMaxWidth)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.88,
        expand: false,
        builder: (_, scrollCtrl) => Column(
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Jump to Ayah',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                itemCount: arabicBlockList.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 64),
                itemBuilder: (_, i) {
                  final block = arabicBlockList[i];
                  final start = block.verseFrom ?? i + 1;
                  final end = block.verseTo ?? i + 1;
                  final startArabic = _toArabicNumerals(start);
                  final endArabic = _toArabicNumerals(end);
                  final label = start == end
                      ? 'Ayah $startArabic'
                      : 'Ayah $startArabic – $endArabic';
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
                        startArabic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(label),
                    onTap: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _ensureAyahVisible(i);
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSurahInfo(BuildContext context, SurahProvider controller) {
    if (controller.surahList.isEmpty ||
        controller.index >= controller.surahList.length) {
      return;
    }
    final surah = controller.surahList[controller.index];
    final isMl = context.read<LanguageProvider>().isMalayalam;

    final bsMaxWidth = ResponsiveHelper.bottomSheetMaxWidth(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: bsMaxWidth != null
          ? BoxConstraints(maxWidth: bsMaxWidth)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Column(
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
            // Surah Arabic name header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                surah.arabicName,
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'Al Mushaf',
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            // Metadata chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _infoChip(
                    isMl ? 'അവതരണം :' : 'Revelation :',
                    _isMeccan(surah.place)
                        ? (isMl ? 'മക്ക' : 'Makkah')
                        : (isMl ? 'മദീന' : 'Madinah'),
                  ),
                  _infoChip(
                    isMl ? 'സൂക്തങ്ങൾ :' : 'Verses :',
                    _toArabicNumerals(surah.ayathCount),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Preface sections
            Expanded(
              child: FutureBuilder(
                future: PrefaceDbHelper.getPrefaceBySurahId(surah.surahNumber, malayalam: isMl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Failed to load surah info.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  final prefaceList = snapshot.data ?? [];
                  if (prefaceList.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No description available for this surah.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: prefaceList.length,
                    itemBuilder: (_, i) {
                      final preface = prefaceList[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (preface.prefaceSubTitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  preface.prefaceSubTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              preface.prefaceText,
                              style: const TextStyle(fontSize: 14, height: 1.6),
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
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Splits a combined Arabic block text at verse-end markers (﴿N﴾) and
  /// returns a list of [TextSpan]s where only the segment belonging to
  /// [playingAyahId] is coloured with [highlightColor].
  /// Selected ayahs (via [controller]) get a background highlight.
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
      final isSelected = controller.isAyahSelected(verseFrom);
      return [
        TextSpan(
          text: arabicText,
          style: baseStyle.copyWith(
            color: isPlaying ? highlightColor : null,
            backgroundColor: isSelected
                ? const Color(0xFF338FCC).withValues(alpha: 0.25)
                : null,
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
      final isSelected = controller.isAyahSelected(currentAyah);
      final ayahNum = currentAyah;
      spans.add(
        TextSpan(
          text: segment,
          style: baseStyle.copyWith(
            color: isPlaying ? highlightColor : null,
            backgroundColor: isSelected
                ? const Color(0xFF338FCC).withValues(alpha: 0.25)
                : null,
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
              spans.add(
                TextSpan(
                  text: cleaned,
                  style: AppTextTheme.surahMalayalamStyle(context),
                ),
              );
              final num = block.translationNo;
              spans.add(
                TextSpan(
                  text: ' ($num)',
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showInterpretationSheet(
                      context,
                      controller,
                      blockAyah,
                      pageNumber: num,
                    ),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.appIconTheme,
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
                  spans.add(
                    TextSpan(
                      text: cleaned.substring(lastEnd, match.start),
                      style: AppTextTheme.surahMalayalamStyle(context),
                    ),
                  );
                }
                final num = int.tryParse(match.group(1)!);
                spans.add(
                  TextSpan(
                    text: '(${match.group(1)})',
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showInterpretationSheet(
                        context,
                        controller,
                        blockAyah,
                        pageNumber: num,
                      ),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.appIconTheme,
                    ),
                  ),
                );
                lastEnd = match.end;
              }
              if (found && lastEnd < cleaned.length) {
                spans.add(
                  TextSpan(
                    text: cleaned.substring(lastEnd),
                    style: AppTextTheme.surahMalayalamStyle(context),
                  ),
                );
              }
              if (!found) {
                spans.add(
                  TextSpan(
                    text: cleaned,
                    style: AppTextTheme.surahMalayalamStyle(context),
                  ),
                );
                // In Malayalam mode, add a tappable interpretation indicator
                // since Malayalam translations don't have embedded (N) refs.
                if (isMl) {
                  spans.add(
                    TextSpan(
                      text: ' ($blockAyah) ',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _showInterpretationSheet(
                          context,
                          controller,
                          blockAyah,
                          pageNumber: blockAyah,
                        ),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.appIconTheme,
                      ),
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
              textAlign: fontSettings.translationJustify
                  ? TextAlign.justify
                  : TextAlign.start,
            ),
          );
        }).toList(),
      ),
    );
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
    final bsMaxWidth = ResponsiveHelper.bottomSheetMaxWidth(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: bsMaxWidth != null
          ? BoxConstraints(maxWidth: bsMaxWidth)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer<SurahProvider>(
        builder: (ctx, ctrl, _) {
          final isMl = ctx.read<LanguageProvider>().isMalayalam;
          final fontSettings = Provider.of<FontSizeChangerProvider>(ctx);
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

          // Build combined text for copy/share
          String combinedText() {
            if (ctrl.surahList.isEmpty) return '';
            final surah = ctrl.surahList[ctrl.index];
            final header = hasBounds
                ? '${surah.name} — ${ctrl.interpretationList.isNotEmpty ? '(${ctrl.interpretationList.first.interpretationNumber})' : ''}'
                : surah.name;
            final body = ctrl.interpretationList
                .map((e) => e.interpretationText)
                .join('\n\n');
            return '$header\n\n$body';
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Header row: title + page counter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        isMl ? 'വിശദീകരണം' : 'Explanation',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      if (!isLoading && hasBounds)
                        Text(
                          '${ctrl.currentInterpretationNumber} / ${ctrl.maxInterpretationNumber}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 16),
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
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: ctrl.interpretationList.map((item) {
                                final rangeLabel =
                                    item.ayaRangeStart == item.ayaRangeEnd
                                    ? '${item.ayaRangeStart}'
                                    : '${item.ayaRangeStart}–${item.ayaRangeEnd}';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(ctx).textTheme.bodyLarge?.color ?? const Color.fromRGBO(124, 58, 40, 1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '($rangeLabel)',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.interpretationText,
                                        style:
                                            AppTextTheme.surahInterpretationStyle(
                                              ctx,
                                            ),
                                        textAlign:
                                            fontSettings.interpretationJustify
                                            ? TextAlign.justify
                                            : TextAlign.start,
                                      ),
                                    ],
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
                  padding: EdgeInsets.fromLTRB(
                    8,
                    4,
                    8,
                    MediaQuery.of(ctx).padding.bottom + 8,
                  ),
                  child: Row(
                    children: [
                      // Prev
                      IconButton(
                        tooltip: 'Previous',
                        onPressed: canPrev
                            ? () => ctrl.navigateInterpretation(false)
                            : null,
                        icon: Icon(
                          Icons.chevron_left,
                          color: canPrev
                              ? AppTheme.appIconTheme
                              : Colors.grey[400],
                        ),
                      ),
                      if (!isLoading && hasBounds)
                        Text(
                          '${ctrl.currentInterpretationNumber} / ${ctrl.maxInterpretationNumber}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      // Next
                      IconButton(
                        tooltip: 'Next',
                        onPressed: canNext
                            ? () => ctrl.navigateInterpretation(true)
                            : null,
                        icon: Icon(
                          Icons.chevron_right,
                          color: canNext
                              ? AppTheme.appIconTheme
                              : Colors.grey[400],
                        ),
                      ),
                      const Spacer(),
                      // Copy
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
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: Icon(
                          Icons.copy_outlined,
                          color: isLoading
                              ? Colors.grey[400]
                              : AppTheme.appIconTheme,
                        ),
                      ),
                      // Share
                      IconButton(
                        tooltip: 'Share',
                        onPressed: isLoading
                            ? null
                            : () async {
                                final text = combinedText();
                                if (text.trim().isNotEmpty) {
                                  await Share.share(text);
                                }
                              },
                        icon: Icon(
                          Icons.share_outlined,
                          color: isLoading
                              ? Colors.grey[400]
                              : AppTheme.appIconTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLabelDialog(
    BuildContext context,
    SurahProvider controller,
    int surahNumber,
    int ayaStart, {
    String? surahName,
    String? ayaText,
    String? surahArabicName,
  }) {
    final isBookmarked = controller.isAyahBookmarked(surahNumber, ayaStart);
    final matches = controller.bookmarkedList.where(
      (b) => b.surahNumber == surahNumber && b.ayahId == ayaStart,
    );
    final initialLabel = matches.isNotEmpty ? matches.first.label ?? '' : '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LabelDialog(
        initialLabel: initialLabel,
        isBookmarked: isBookmarked,
        controller: controller,
        surahNumber: surahNumber,
        ayaStart: ayaStart,
        surahName: surahName,
        ayaText: ayaText,
        surahArabicName: surahArabicName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SurahProvider>(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _saveLastRead();
          Provider.of<AudioProvider>(context, listen: false).stopAudio();
        }
      },
      child: BaseScreenLayout(
        appBar: CommonAppBar.appBar(
          context,
          onSurahInfoTap: _hasPreface
              ? () => _showSurahInfo(context, controller)
              : null,
        ),
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
            if (controller.arabicBlockList.isNotEmpty) ...[
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'jumpToAyah',
                mini: true,
                tooltip: 'Jump to Ayah',
                onPressed: () =>
                    _showJumpTo(context, controller.arabicBlockList),
                child: const Icon(Icons.format_list_numbered),
              ),
            ],
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
                child: controller.arabicBlockList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Builder(
                        builder: (_) {
                          final surahNumber = controller.surahList.isNotEmpty
                              ? controller.surahList[controller.index].surahNumber
                              : 0;
                          final surahName = controller.surahList.isNotEmpty
                              ? controller.surahList[controller.index].name
                              : 'Surah';
                          final hPad = ResponsiveHelper.horizontalPadding(
                            context,
                          );
                          return Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(controller.index),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              builder: (context, opacity, child) {
                                return Opacity(opacity: opacity, child: child);
                              },
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onHorizontalDragEnd: _handleContinuousModeSwipe,
                                child: ResponsiveContentWrapper(
                                  child: CustomScrollView(
                                    controller: _scrollController,
                                    slivers: [
                                      const SurahScreenAppBar(),
                                      SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                            final block = controller.arabicBlockList[index];
                            final ayaStart = block.verseFrom ?? index + 1;
                            final ayaEnd = block.verseTo ?? index + 1;
                            final arabicText = block.arabicText ?? '';
                            final ayahRange = ayaStart == ayaEnd
                                ? 'Ayah ${_toArabicNumerals(ayaStart)}'
                                : 'Ayahs ${_toArabicNumerals(ayaStart)} to ${_toArabicNumerals(ayaEnd)}';

                            return Semantics(
                              label: '$surahName, $ayahRange',
                              child: Consumer<AudioProvider>(
                                key: _itemKeys[index],
                                builder: (highlightCtx, audio, _) {
                                  // Null when audio is inactive or playing a
                                  // different surah; otherwise the individual
                                  // ayah number currently being played.
                                  final effectivePlayingAyahId =
                                      audio.isActive &&
                                          surahNumber > 0 &&
                                          audio.currentSurahNumber ==
                                              surahNumber
                                      ? audio.playingAyahId
                                      : null;
                                  return Padding(
                                    key: ValueKey(index),
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      8,
                                      4,
                                      4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (arabicText.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Consumer<TajweedProvider>(
                                                  builder: (ctx, tajweed, _) {
                                                    final quranJustify =
                                                        Provider.of<
                                                              FontSizeChangerProvider
                                                            >(ctx)
                                                            .quranJustify;
                                                    if (tajweed.enabled &&
                                                        tajweed
                                                            .downloadComplete) {
                                                      return _TajweedWordRow(
                                                        surahNo: surahNumber,
                                                        verseFrom: ayaStart,
                                                        verseTo: ayaEnd,
                                                        playingAyahId:
                                                            effectivePlayingAyahId,
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
                                                      textHeightBehavior:
                                                          const TextHeightBehavior(
                                                            applyHeightToFirstAscent:
                                                                false,
                                                            applyHeightToLastDescent:
                                                                false,
                                                          ),
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      textAlign: quranJustify
                                                          ? TextAlign.justify
                                                          : TextAlign.start,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 10),
                                              ],
                                            ),
                                          ),
                                        if (controller
                                            .translationBlockList
                                            .isNotEmpty)
                                          _buildTranslationBlocks(
                                            context,
                                            controller.translationBlockList,
                                            ayaStart,
                                            ayaEnd,
                                            surahNumber,
                                            controller,
                                          ),
                                        // ── Action row: Bookmark | Share | Play ──
                                        Builder(
                                          builder: (context) {
                                            final isBookmarked = controller
                                                .isAyahBookmarked(
                                                  surahNumber,
                                                  ayaStart,
                                                );
                                            const translationText = '';
                                            return Row(
                                                  children: [
                                                    // Bookmark
                                                    IconButton(
                                                      tooltip: isBookmarked
                                                          ? 'Remove bookmark'
                                                          : 'Bookmark',
                                                      onPressed: () {
                                                        if (isBookmarked) {
                                                          controller
                                                              .onBookMarkRemoveByAyah(
                                                                surahNumber,
                                                                ayaStart,
                                                              );
                                                        } else {
                                                          final surah =
                                                              controller
                                                                  .surahList[controller
                                                                  .index];
                                                          controller.onBookMarkAdd(
                                                            surahNumber,
                                                            ayaStart,
                                                            surahName:
                                                                surah.name,
                                                            ayaText:
                                                                arabicText
                                                                    .isNotEmpty
                                                                ? arabicText
                                                                : null,
                                                            surahArabicName:
                                                                surah
                                                                    .arabicName,
                                                          );
                                                        }
                                                      },
                                                      icon: Icon(
                                                        isBookmarked
                                                            ? Icons.bookmark
                                                            : Icons
                                                                  .bookmark_border_outlined,
                                                        color: AppTheme.appIconTheme,
                                                      ),
                                                    ),
                                                    // Label
                                                    IconButton(
                                                      tooltip: 'Label',
                                                      onPressed: () {
                                                        final surah =
                                                            controller
                                                                .surahList[controller
                                                                .index];
                                                        _showLabelDialog(
                                                          context,
                                                          controller,
                                                          surahNumber,
                                                          ayaStart,
                                                          surahName: surah.name,
                                                          ayaText:
                                                              arabicText
                                                                  .isNotEmpty
                                                              ? arabicText
                                                              : null,
                                                          surahArabicName:
                                                              surah.arabicName,
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        Icons.label_outline,
                                                        color: AppTheme.appIconTheme,
                                                      ),
                                                    ),
                                                    // Share
                                                    IconButton(
                                                      tooltip: 'Share',
                                                      onPressed: () async {
                                                        final surah =
                                                            controller
                                                                .surahList[controller
                                                                .index];
                                                        final shareText =
                                                            '${surah.name} – Ayah ${_toArabicNumerals(ayaStart)}\n\n'
                                                            '${arabicText.isNotEmpty ? '$arabicText\n\n' : ''}'
                                                            '$translationText';
                                                        if (shareText
                                                            .trim()
                                                            .isNotEmpty) {
                                                          await Share.share(
                                                            shareText,
                                                          );
                                                        }
                                                      },
                                                      icon: const Icon(
                                                        Icons.share_outlined,
                                                        color: AppTheme.appIconTheme,
                                                      ),
                                                    ),
                                                    // Play / Stop
                                                    Consumer<AudioProvider>(
                                                      builder: (ctx, audio, _) {
                                                        final isThis = audio
                                                            .isCurrentAyah(
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
                                                                    listen:
                                                                        false,
                                                                  );
                                                              audio.playAyah(
                                                                surahNumber:
                                                                    surahNumber,
                                                                ayahId:
                                                                    ayaStart,
                                                                ayahEndId:
                                                                    ayaEnd,
                                                                translationIndex:
                                                                    index,
                                                                reciterFolder: ps
                                                                    .selectedReciter
                                                                    .folderName,
                                                                playbackSpeed: ps
                                                                    .playbackSpeed,
                                                              );
                                                            }
                                                          },
                                                          icon: isLoadingThis
                                                              ? const SizedBox(
                                                                  width: 20,
                                                                  height: 20,
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: AppTheme.appIconTheme,
                                                                  ),
                                                                )
                                                              : Icon(
                                                                  isThis
                                                                      ? Icons
                                                                            .stop_circle
                                                                      : Icons
                                                                            .play_circle_outline,
                                                                  color: AppTheme.appIconTheme,
                                                                ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                );
                                          },
                                        ),
                                        const Divider(thickness: 0.5),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          childCount: controller.arabicBlockList.length,
                                        ),
                                      ),
                                      // ── Bottom surah navigation arrows ──
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 16,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (_canNavigateToAdjacentSurah(false))
                                                IconButton(
                                                  tooltip: 'Next surah',
                                                  onPressed: () =>
                                                      _navigateToAdjacentSurah(false),
                                                  icon: const Icon(
                                                    Icons.arrow_back_ios_new,
                                                    color: AppTheme.appIconTheme,
                                                  ),
                                                )
                                              else
                                                const SizedBox(width: 48),
                                              const Spacer(),
                                              if (_canNavigateToAdjacentSurah(true))
                                                IconButton(
                                                  tooltip: 'Previous surah',
                                                  onPressed: () =>
                                                      _navigateToAdjacentSurah(true),
                                                  icon: const Icon(
                                                    Icons.arrow_forward_ios_rounded,
                                                    color: AppTheme.appIconTheme,
                                                  ),
                                                )
                                              else
                                                const SizedBox(width: 48),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
                    ? 'Ayah ${_toArabicNumerals(audio.playingAyahId!)}'
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
                                      reciterFolder: playSettings
                                          .selectedReciter
                                          .folderName,
                                      playbackSpeed: playSettings.playbackSpeed,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.skip_previous, color: AppTheme.appIconTheme),
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
                            icon: const Icon(Icons.stop, color: AppTheme.appIconTheme),
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
                                      reciterFolder: playSettings
                                          .selectedReciter
                                          .folderName,
                                      playbackSpeed: playSettings.playbackSpeed,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.skip_next, color: AppTheme.appIconTheme),
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

class _LabelDialog extends StatefulWidget {
  final String initialLabel;
  final bool isBookmarked;
  final SurahProvider controller;
  final int surahNumber;
  final int ayaStart;
  final String? surahName;
  final String? ayaText;
  final String? surahArabicName;

  const _LabelDialog({
    required this.initialLabel,
    required this.isBookmarked,
    required this.controller,
    required this.surahNumber,
    required this.ayaStart,
    this.surahName,
    this.ayaText,
    this.surahArabicName,
  });

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
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
      title: const Text('Label Ayah'),
      content: TextField(
        controller: _textController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Enter a label…',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (widget.isBookmarked) {
              widget.controller.updateBookmarkLabel(
                widget.surahNumber,
                widget.ayaStart,
                null,
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final label = _textController.text.trim();
            if (!widget.isBookmarked) {
              await widget.controller.onBookMarkAdd(
                widget.surahNumber,
                widget.ayaStart,
                surahName: widget.surahName,
                ayaText: widget.ayaText,
                surahArabicName: widget.surahArabicName,
              );
            }
            widget.controller.updateBookmarkLabel(
              widget.surahNumber,
              widget.ayaStart,
              label.isEmpty ? null : label,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ── Tajweed word-image row ────────────────────────────────────────────────────

class _TajweedWordRow extends StatefulWidget {
  const _TajweedWordRow({
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
    final quranJustify = Provider.of<FontSizeChangerProvider>(
      context,
    ).quranJustify;
    final words = _words;
    if (words == null) {
      return const SizedBox(
        height: 40,
        child: Center(
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
                  height: 40,
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

    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: quranJustify
          ? WrapAlignment.spaceBetween
          : WrapAlignment.start,
      spacing: 4,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
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
    // U+FD3E ﴾ and U+FD3F ﴿ are the Arabic ornamental parentheses that
    // bracket ayah numbers — exactly matching the reference image style.
    // TextDirection.ltr prevents the bidi algorithm from mirroring the glyphs.
    final badge = Text(
      '\uFD3E${_toArabicNumerals(number)}\uFD3F',
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontFamily: 'Uthmani',
        fontSize: 20,
        color: highlighted
            ? AppTheme.appIconTheme
            : Theme.of(context).colorScheme.primary,
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
