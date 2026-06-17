import 'dart:collection';
import 'dart:developer';

import 'package:flutter/services.dart';

import 'tajweed_font_download_service.dart';

/// Thrown when a page's Tajweed font is not installed on device.
class TajweedFontNotInstalledError implements Exception {
  const TajweedFontNotInstalledError(this.pageNo);
  final int pageNo;

  @override
  String toString() =>
      'Tajweed font for page $pageNo is not installed. '
      'Please download the Tajweed font pack.';
}

/// Manages runtime loading of per-page QCF V4 COLR Tajweed fonts via
/// [FontLoader].
///
/// Each page font is loaded once and cached using LRU eviction.
/// Adjacent pages are preloaded in the background.
class TajweedFontService {
  TajweedFontService._();

  static final TajweedFontService instance = TajweedFontService._();

  static const int _maxCachedFonts = 10;
  static const int _totalPages = 604;

  final LinkedHashSet<String> _loadedFamilies = LinkedHashSet<String>();
  final Map<String, Future<String>> _loading = {};

  /// Returns the font-family name used for [pageNo] in TextStyle.
  static String familyForPage(int pageNo) => 'TAJWEED_P${_pad(pageNo)}';

  /// Ensures the font for [pageNo] is loaded and returns its family name.
  ///
  /// Throws [TajweedFontNotInstalledError] if the TTF file is not on disk.
  Future<String> ensurePageFont(int pageNo) async {
    final family = familyForPage(pageNo);

    if (_loadedFamilies.contains(family)) {
      // Move to end (most-recently used).
      _loadedFamilies.remove(family);
      _loadedFamilies.add(family);
      return family;
    }

    if (_loading.containsKey(family)) {
      return _loading[family]!;
    }

    final completer = _loadFont(pageNo, family);
    _loading[family] = completer;
    try {
      return await completer;
    } finally {
      _loading.remove(family);
    }
  }

  Future<String> _loadFont(int pageNo, String family) async {
    final file =
        await TajweedFontDownloadService.instance.fontFileForPage(pageNo);
    if (file == null) throw TajweedFontNotInstalledError(pageNo);

    final bytes = await file.readAsBytes();
    final loader = FontLoader(family);
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();

    _loadedFamilies.add(family);
    while (_loadedFamilies.length > _maxCachedFonts) {
      final evicted = _loadedFamilies.first;
      _loadedFamilies.remove(evicted);
      log('TajweedFont: evicted $evicted from cache');
    }

    log('TajweedFont: loaded $family');
    return family;
  }

  /// Preloads fonts for pages adjacent to [pageNo] in the background.
  Future<void> preloadAdjacent(int pageNo, {int totalPages = _totalPages}) async {
    final neighbours = <int>[
      if (pageNo > 1) pageNo - 1,
      if (pageNo < totalPages) pageNo + 1,
    ];
    await Future.wait(
      neighbours.map((p) async {
        try {
          await ensurePageFont(p);
        } on TajweedFontNotInstalledError {
          // Not installed – silently skip.
        } catch (e) {
          log('TajweedFont: preload p$p failed: $e');
        }
      }),
      eagerError: false,
    );
  }

  /// Returns `true` if the font TTF for [pageNo] is present on disk.
  Future<bool> isFontAvailable(int pageNo) async {
    final file =
        await TajweedFontDownloadService.instance.fontFileForPage(pageNo);
    return file != null;
  }

  static String _pad(int pageNo) {
    if (pageNo < 10) return '00$pageNo';
    if (pageNo < 100) return '0$pageNo';
    return '$pageNo';
  }
}
