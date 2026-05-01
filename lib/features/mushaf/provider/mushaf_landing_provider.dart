import 'dart:developer';

import 'package:flutter/material.dart';

import '../data/mushaf_repository.dart';
import '../db/local_database.dart';
import '../services/mushaf_install_state.dart';

/// State for the Mushaf landing / surah-list screen.
class MushafLandingProvider extends ChangeNotifier {
  MushafLandingProvider() {
    _repository = MushafRepository(localDatabase: LocalDatabase.instance);
    _loadAll();
  }

  late final MushafRepository _repository;
  MushafRepository get repository => _repository;

  ({int page, int suraNo, int ayaNo})? lastRead;
  List<({int juzNo, int firstPage})> juzPages = [];
  bool sortAscending = true;
  bool fontsInstalled = false;

  static const int previewPageLimit = 2;

  Future<void> _loadAll() async {
    await Future.wait([
      _checkFontsInstalled(),
      loadLastRead(),
      _loadJuzPages(),
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

  void setFontsInstalled() {
    fontsInstalled = true;
    notifyListeners();
  }
}
