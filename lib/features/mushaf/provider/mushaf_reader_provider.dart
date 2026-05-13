import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import 'package:the_message_of_the_quran/core/services/audio_handler.dart';
import '../data/mushaf_repository.dart';
import '../db/local_database.dart';
import '../models/page_meta.dart';
import '../services/mushaf_install_state.dart';

/// Holds all mutable state for the Mushaf reader screen.
class MushafReaderProvider extends ChangeNotifier {
  MushafReaderProvider({
    required QuranAudioHandler handler,
    int? initialPage,
    int? initialSurahNo,
    int? initialAyaNo,
  })  : _handler = handler,
        _requestedPage = initialPage,
        _initialSurahNo = initialSurahNo,
        _initialAyaNo = initialAyaNo;

  final QuranAudioHandler _handler;
  AudioPlayer get audioPlayer => _handler.player;

  static const int previewLimit = 2;
  static const int totalPages = 604;
  static const double kSurahHeaderHeight = 130.0;

  late final MushafRepository repository;

  final int? _requestedPage;
  final int? _initialSurahNo;
  final int? _initialAyaNo;

  bool fontsInstalled = false;
  bool initialised = false;
  int currentPage = 1;

  int? selectedAyaId;
  int? selectedSuraNo;
  int? selectedAyaNo;

  bool isLoadingAudio = false;
  bool isPlaying = false;
  String? playingLabel;
  int? playingAyaId;

  List<int> playlistAyaIds = [];
  List<String> playlistLabels = [];
  List<int> playlistSuraNos = [];
  List<int> playlistAyaNos = [];
  StreamSubscription<int?>? _playlistIndexSub;
  bool followingPlayback = true;

  bool isListView = false;
  List<PageMeta?> allPageMetas = [];
  Map<int, String> surahGlyphs = {};
  Map<int, String> bismillahGlyphs = {};
  List<MushafListItem> listItems = [];
  double listPageHeight = 0;

  bool isAutoNavigating = false;

  int? audioPlayingAyaId;

  VoidCallback? onManualScrollWhilePlaying;
  bool _scrollConfirmationPending = false;

  StreamSubscription<PlayerState>? _playerStateSub;

  PageController? pageController;
  ScrollController listScrollController = ScrollController();

  Future<void> init() async {
    repository = MushafRepository(localDatabase: LocalDatabase.instance);
    _playerStateSub = audioPlayer.playerStateStream.listen(_onPlayerStateChanged);
    await _doInit();
  }

  Future<void> _doInit() async {
    await MushafInstallState.instance.recoverFromInterrupted();

    final installed = await MushafInstallState.instance.isFullFontsInstalled;
    int startPage =
        _requestedPage ?? await MushafInstallState.instance.lastOpenPage;

    if (_initialSurahNo != null && _initialAyaNo != null) {
      final ayaId =
          await repository.getContinuesAyaId(_initialSurahNo, _initialAyaNo);
      if (ayaId > 0) {
        final page = await repository.getPageForAya(ayaId);
        if (page > 0 && (installed || page <= previewLimit)) {
          startPage = page;
        }
      }
    }

    if (!installed && startPage > previewLimit) startPage = previewLimit;
    startPage = startPage.clamp(1, totalPages);

    await MushafInstallState.instance.saveLastOpenPage(startPage);

    fontsInstalled = installed;
    currentPage = startPage;
    pageController = PageController(initialPage: startPage - 1);
    initialised = true;
    notifyListeners();

    _loadListViewData();
  }

  Future<void> _loadListViewData() async {
    final metas = await repository.getAllPageMetas();
    final glyphs = await repository.getAllSurahGlyphs();
    final bGlyphs = await repository.getAllBismillahGlyphs();

    allPageMetas = metas;
    surahGlyphs = glyphs;
    bismillahGlyphs = bGlyphs;
    _buildListItems();
    notifyListeners();
  }

  void _buildListItems() {
    final items = <MushafListItem>[];
    for (int i = 0; i < totalPages; i++) {
      items.add(MushafListPage(i + 1));
    }
    listItems = items;
  }

  List<MushafListItem> getVisibleListItems() {
    if (fontsInstalled) return listItems;
    final result = <MushafListItem>[];
    for (final item in listItems) {
      if (item is MushafListPage && item.pageNo > previewLimit) break;
      result.add(item);
    }
    return result;
  }

  void _onPlayerStateChanged(PlayerState state) {
    final playing =
        state.playing && state.processingState != ProcessingState.completed;
    isPlaying = playing;
    if (state.processingState == ProcessingState.completed) {
      // Determine the surah that just finished before clearing state.
      final finishedSuraNo =
          playlistSuraNos.isNotEmpty ? playlistSuraNos.last : null;
      playingLabel = null;
      playingAyaId = null;
      audioPlayingAyaId = null;
      notifyListeners();
      // Auto-advance to the next surah (1-114).
      // Use microtask (not a long delay) so that _playFromSurah runs while
      // the native player is still active.  A long delay risks the player
      // auto-deactivating which causes the _setPlatformActive race.
      if (finishedSuraNo != null && finishedSuraNo < 114) {
        Future.microtask(() => _playFromSurah(finishedSuraNo + 1));
      }
      return;
    }
    notifyListeners();
  }

  void onPageChanged(int index) {
    final page = index + 1;
    currentPage = page;
    MushafInstallState.instance.saveLastOpenPage(page);

    if (selectedAyaId != null) {
      selectedAyaId = null;
      selectedSuraNo = null;
      selectedAyaNo = null;
    }

    if (isAutoNavigating) {
      isAutoNavigating = false;
    } else if (isPlaying && followingPlayback) {
      requestScrollConfirmation();
    }
    notifyListeners();
  }

  void onListScrollUpdate(double offset, double pageH) {
    if (pageH <= 0) return;
    if (isAutoNavigating) return;
    final index = (offset / pageH).floor().clamp(0, totalPages - 1);
    final page = index + 1;
    if (currentPage != page) {
      currentPage = page;
      MushafInstallState.instance.saveLastOpenPage(page);
      notifyListeners();
    }
  }

  void requestScrollConfirmation() {
    if (_scrollConfirmationPending) return;
    _scrollConfirmationPending = true;
    onManualScrollWhilePlaying?.call();
  }

  void resolveScrollConfirmation({required bool stopFollowing}) {
    _scrollConfirmationPending = false;
    if (stopFollowing) {
      followingPlayback = false;
      notifyListeners();
    }
  }

  Future<void> updateAudioHighlight(int? surahNo, int? ayaNo) async {
    if (surahNo == null || ayaNo == null || ayaNo <= 0) {
      if (audioPlayingAyaId != null) {
        audioPlayingAyaId = null;
        notifyListeners();
      }
      return;
    }
    try {
      final ayaId = await repository.getContinuesAyaId(surahNo, ayaNo);
      if (ayaId <= 0) return;
      if (audioPlayingAyaId == ayaId) return;
      audioPlayingAyaId = ayaId;
      notifyListeners();
      await navigateToAyaPage(ayaId);
    } catch (e) {
      log('MushafReaderProvider: updateAudioHighlight error – $e');
    }
  }

  Future<void> navigateToAyaPage(int ayaId) async {
    if (!followingPlayback) return;
    try {
      final page = await repository.getPageForAya(ayaId);
      if (page <= 0) return;
      if (!isListView && page == currentPage) return;
      isAutoNavigating = true;
      if (isListView) {
        _pendingScrollPage = page;
        notifyListeners();
      } else {
        pageController?.jumpToPage(page - 1);
      }
    } catch (e) {
      log('MushafReader: _navigateToAyaPage error – $e');
    }
  }

  int? _pendingScrollPage;
  int? consumePendingScrollPage() {
    final p = _pendingScrollPage;
    _pendingScrollPage = null;
    return p;
  }

  void tryNavigateTo(int page) {
    final clamped = page.clamp(1, totalPages);
    if (fontsInstalled || clamped <= previewLimit) {
      if (isListView) {
        _pendingScrollPage = clamped;
        notifyListeners();
      } else {
        pageController?.animateToPage(
          clamped - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void setFontsInstalled() {
    fontsInstalled = true;
    notifyListeners();
  }

  void toggleListView() {
    isListView = !isListView;
    notifyListeners();
  }

  void onAyaTap(int ayaId, int suraId) {
    if (ayaId <= 0) return;
    if (selectedAyaId == ayaId) {
      selectedAyaId = null;
      selectedSuraNo = null;
      selectedAyaNo = null;
      notifyListeners();
      return;
    }
    selectedAyaId = ayaId;
    selectedSuraNo = null;
    selectedAyaNo = null;
    notifyListeners();

    repository.getAyaInfo(ayaId).then((info) {
      if (selectedAyaId != ayaId) return;
      selectedSuraNo = info.suraNo;
      selectedAyaNo = info.ayaNo;
      notifyListeners();
    }).catchError((e) { log('MushafReader: getAyaInfo error – $e'); });
  }

  void clearSelection() {
    selectedAyaId = null;
    selectedSuraNo = null;
    selectedAyaNo = null;
    notifyListeners();
  }

  Future<void> onPlayPressed() async {
    if (isLoadingAudio) return;
    if (selectedAyaId == playingAyaId) {
      if (isPlaying) {
        await _handler.pause();
        return;
      }
      if (playingLabel != null) {
        await _handler.play();
        return;
      }
    }

    int suraNo;
    int startAyaNo = 1;
    if (selectedAyaId != null) {
      final info = await repository.getAyaInfo(selectedAyaId!);
      suraNo = info.suraNo;
      startAyaNo = info.ayaNo;
    } else {
      final meta = await repository.getPageMeta(currentPage);
      suraNo = meta?.suraNo ?? 1;
    }

    await _playFromSurah(suraNo, startAyaNo: startAyaNo);
  }

  /// Sets audio source with fallback.  On an active player setAudioSource
  /// works immediately (just_audio fast path).  If it fails (player
  /// auto-deactivated), tries seek+retry, then recreate via handler as last
  /// resort inside a guarded zone.
  Future<void> _setAudioSourceWithFallback(AudioSource source) async {
    try {
      await audioPlayer.setAudioSource(source, initialIndex: 0);
    } catch (e) {
      log('MushafReader: setAudioSource failed – $e');

      // ── Fallback 1: seek to reset player state, then retry. ──
      try {
        log('MushafReader: trying seek(0) + retry');
        await audioPlayer.seek(Duration.zero, index: 0);
        await audioPlayer.setAudioSource(source, initialIndex: 0);
        return;
      } catch (e2) {
        log('MushafReader: seek+retry failed – $e2');
      }

      // ── Fallback 2: recreate player via handler (last resort). ──
      log('MushafReader: recreating player via handler');
      _playerStateSub?.cancel();
      _playlistIndexSub?.cancel();

      final completer = Completer<void>();
      runZonedGuarded(() async {
        _handler.recreatePlayer();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        _playerStateSub = audioPlayer.playerStateStream.listen(_onPlayerStateChanged);
        await audioPlayer.setAudioSource(source, initialIndex: 0);
        if (!completer.isCompleted) completer.complete();
      }, (error, stack) {
        log('MushafReader: guarded zone caught – $error');
        if (!completer.isCompleted) completer.completeError(error, stack);
      });
      await completer.future;
    }
  }

  /// Fetches audio for [suraNo] starting from [startAyaNo] and begins
  /// playback.  Used both by [onPlayPressed] and auto-advance on completion.
  Future<void> _playFromSurah(int suraNo, {int startAyaNo = 1}) async {
    if (isLoadingAudio) return;

    isLoadingAudio = true;
    notifyListeners();
    _playlistIndexSub?.cancel();
    _handler.clearSkipDelegate();

    // Do NOT call audioPlayer.stop() before setAudioSource.  stop()
    // transitions ExoPlayer to idle which internally fires
    // _setPlatformActive(false).  That races with _setPlatformActive(true)
    // from setAudioSource and causes PlatformException or
    // "Cannot complete a future with itself".

    try {
      const reciterId = 7;
      final response = await http
          .get(Uri.parse(
            'https://api.quran.com/api/v4/verses/by_chapter/$suraNo'
            '?audio=$reciterId&per_page=300',
          ))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('API error ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final verses = (data['verses'] as List).cast<Map<String, dynamic>>();

      final sources = <AudioSource>[];
      final labels = <String>[];
      final newAyaIds = <int>[];
      final suraNumbers = <int>[];
      final ayaNumbers = <int>[];

      final allAyaIds = await repository.getContinuousAyaIdsForSurah(suraNo);

      for (final v in verses) {
        final ayaNo = v['verse_number'] as int;
        if (ayaNo < startAyaNo) continue;
        final audioPath = (v['audio'] as Map?)?['url'] as String?;
        if (audioPath == null || audioPath.isEmpty) continue;

        sources.add(AudioSource.uri(
          Uri.parse('https://audio.qurancdn.com/$audioPath'),
        ));
        labels.add('$suraNo:$ayaNo');
        suraNumbers.add(suraNo);
        ayaNumbers.add(ayaNo);
        final idxInAll = ayaNo - 1;
        newAyaIds.add(
          idxInAll < allAyaIds.length ? allAyaIds[idxInAll] : 0,
        );
      }

      if (sources.isEmpty) {
        isLoadingAudio = false;
        notifyListeners();
        return;
      }

      playlistAyaIds = newAyaIds;
      playlistLabels = labels;
      playlistSuraNos = suraNumbers;
      playlistAyaNos = ayaNumbers;

      await _setAudioSourceWithFallback(
        ConcatenatingAudioSource(children: sources),
      );

      _playlistIndexSub = audioPlayer.currentIndexStream.listen((index) {
        final i = index ?? 0;
        if (i < playlistAyaIds.length) {
          final ayaId = playlistAyaIds[i];
          playingAyaId = ayaId;
          audioPlayingAyaId = ayaId;
          playingLabel = playlistLabels[i];
          // Update media notification with current ayah info
          _handler.mediaItem.add(MediaItem(
            id: 'mushaf_${playlistSuraNos[i]}_ayah_${playlistAyaNos[i]}',
            album: 'The Message of the Quran',
            title: 'Surah ${playlistSuraNos[i]} - Ayah ${playlistAyaNos[i]}',
            artist: 'Mishary Rashid Alafasy',
          ));
          notifyListeners();
          navigateToAyaPage(ayaId);
        }
      });

      followingPlayback = true;
      playingLabel = labels.first;
      selectedAyaId = null;
      selectedSuraNo = null;
      selectedAyaNo = null;
      isLoadingAudio = false;
      notifyListeners();

      audioPlayer.play().catchError((e) => log('MushafReader: play error – $e'));
    } catch (e) {
      log('MushafReader: play error – $e');
      isLoadingAudio = false;
      notifyListeners();
    }
  }

  Future<void> stopAndClear() async {
    _playlistIndexSub?.cancel();
    _handler.clearSkipDelegate();
    await _handler.stop();
    playingLabel = null;
    playingAyaId = null;
    audioPlayingAyaId = null;
    selectedAyaId = null;
    playlistAyaIds = [];
    playlistLabels = [];
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _playlistIndexSub?.cancel();
    // Don't dispose the player – it's shared via the handler
    pageController?.dispose();
    listScrollController.dispose();
    super.dispose();
  }
}

abstract class MushafListItem {
  const MushafListItem();
}

class MushafListPage extends MushafListItem {
  const MushafListPage(this.pageNo);
  final int pageNo;
}

class MushafListHeader extends MushafListItem {
  const MushafListHeader({
    required this.suraNo,
    required this.glyph,
    required this.bismillahGlyph,
  });
  final int suraNo;
  final String glyph;
  final String bismillahGlyph;
}
