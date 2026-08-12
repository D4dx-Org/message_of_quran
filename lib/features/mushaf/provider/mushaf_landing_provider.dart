import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mushaf_repository.dart';
import '../services/mushaf_install_state.dart';

/// State for the Mushaf landing / surah-list screen.
class MushafLandingProvider extends ChangeNotifier {
  MushafLandingProvider() {
    _repository = MushafRepository();
    _loadAll();
  }

  bool _isDisposed = false;

  late final MushafRepository _repository;
  MushafRepository get repository => _repository;

  ({int page, int suraNo, int ayaNo})? lastRead;
  List<({int juzNo, int firstPage})> juzPages = [];
  bool sortAscending = true;
  bool fontsInstalled = false;

  static const int previewPageLimit = 2;

  // ─── Independent tab selection tracking ─────────────────────────────────
  static const _kMushafSurahSelection = 'mushaf_surah_tab_selection';
  static const _kMushafJuzSelection = 'mushaf_juz_tab_selection';
  static const _kMushafRevelationSelection = 'mushaf_revelation_tab_selection';

  int? lastMushafSurahSelection;
  int? lastMushafJuzSelection;
  int? lastMushafRevelationSelection;

  Future<void> _loadAll() async {
    await Future.wait([
      _checkFontsInstalled(),
      loadLastRead(),
      _loadJuzPages(),
      _loadTabSelections(),
    ]);
  }

  Future<void> _checkFontsInstalled() async {
    final installed = await MushafInstallState.instance.isFullFontsInstalled;
    fontsInstalled = installed;
    notifyListeners();
  }

  Future<void> refreshAfterReader() async {
    await Future.wait([_checkFontsInstalled(), loadLastRead()]);
  }

  Future<void> loadLastRead() async {
    try {
      final page = await MushafInstallState.instance.lastOpenPage;
      final meta = await _repository.getPageMeta(page);
      if (meta != null) {
        final startInfo = await _repository.getAyaInfo(meta.startAya);
        final ayahNo = startInfo.suraNo == meta.suraNo ? startInfo.ayaNo : 1;
        lastRead = (page: page, suraNo: meta.suraNo, ayaNo: ayahNo);
        notifyListeners();
      }
    } catch (e) {
      log('MushafLanding: _loadLastRead error: $e');
    }
  }

  Future<void> _loadJuzPages() async {
    try {
      final pages = await _repository.getAllJuzFirstPages();
      juzPages = pages;
      notifyListeners();
    } catch (e) {
      log('MushafLanding: _loadJuzPages error: $e');
    }
  }

  Future<int> getFirstPageForSurah(int suraNo) {
    return _repository.getFirstPageForSurah(suraNo);
  }

  Future<int> getPageForSurahAyah(int suraNo, int ayaNo) async {
    final continuesAyaId = await _repository.getContinuesAyaId(suraNo, ayaNo);
    if (continuesAyaId <= 0) return 1;

    final page = await _repository.getPageForAya(continuesAyaId);
    return page > 0 ? page : 1;
  }

  void toggleSort() {
    sortAscending = !sortAscending;
    notifyListeners();
  }

  /// Returns the juz number that the last-read page belongs to, or null.
  int? get lastReadJuzNo {
    final page = lastRead?.page;
    if (page == null || juzPages.isEmpty) return null;
    int? juz;
    for (final jp in juzPages) {
      if (jp.firstPage <= page) {
        juz = jp.juzNo;
      } else {
        break;
      }
    }
    return juz;
  }

  // ─── Tab selection persistence ──────────────────────────────────────────

  Future<void> _loadTabSelections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      lastMushafSurahSelection = prefs.getInt(_kMushafSurahSelection);
      lastMushafJuzSelection = prefs.getInt(_kMushafJuzSelection);
      lastMushafRevelationSelection =
          prefs.getInt(_kMushafRevelationSelection);
      notifyListeners();
    } catch (e) {
      log('MushafLanding: _loadTabSelections error: $e');
    }
  }

  Future<void> saveMushafSurahSelection(int suraNo) async {
    lastMushafSurahSelection = suraNo;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kMushafSurahSelection, suraNo);
    } catch (e) {
      log('MushafLanding: saveMushafSurahSelection error: $e');
    }
  }

  Future<void> saveMushafJuzSelection(int juzNo) async {
    lastMushafJuzSelection = juzNo;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kMushafJuzSelection, juzNo);
    } catch (e) {
      log('MushafLanding: saveMushafJuzSelection error: $e');
    }
  }

  Future<void> saveMushafRevelationSelection(int suraNo) async {
    lastMushafRevelationSelection = suraNo;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kMushafRevelationSelection, suraNo);
    } catch (e) {
      log('MushafLanding: saveMushafRevelationSelection error: $e');
    }
  }

  void setFontsInstalled() {
    fontsInstalled = true;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
