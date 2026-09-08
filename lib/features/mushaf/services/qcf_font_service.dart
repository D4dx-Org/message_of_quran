import 'dart:collection';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'mushaf_font_store.dart';

/// Thrown when a page font is not available (not bundled and not downloaded).
class FontNotInstalledError implements Exception {
  const FontNotInstalledError(this.pageNo);
  final int pageNo;

  @override
  String toString() =>
      'Font for page $pageNo is not installed. '
      'Please download the Mushaf font pack.';
}

/// Manages dynamic loading of QCF page fonts via [FontLoader].
class QcfFontService {
  QcfFontService._();

  static final QcfFontService instance = QcfFontService._();

  static const Set<int> _bundledPages = {1, 2, 305, 603, 604};
  static const int _maxCachedFonts = 10;

  final LinkedHashSet<String> _loadedFamilies = LinkedHashSet<String>();
  final Set<String> _loading = <String>{};

  static String familyForPage(int pageNo) => 'QCF_P${_pad(pageNo)}';
  static const String bsmlFamily = 'QCF_BSML';

  Future<String> ensurePageFont(int pageNo) async {
    final family = familyForPage(pageNo);

    if (_loadedFamilies.contains(family)) {
      _loadedFamilies.remove(family);
      _loadedFamilies.add(family);
      return family;
    }

    if (_loading.contains(family)) {
      while (_loading.contains(family)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return family;
    }

    _loading.add(family);
    try {
      final fontData = await _resolveFontBytes(pageNo);
      final loader = FontLoader(family);
      loader.addFont(Future.value(fontData));
      await loader.load();

      _loadedFamilies.add(family);
      while (_loadedFamilies.length > _maxCachedFonts) {
        final evicted = _loadedFamilies.first;
        _loadedFamilies.remove(evicted);
        log('QcfFont: evicted $evicted from cache');
      }
    } finally {
      _loading.remove(family);
    }

    return family;
  }

  Future<String> ensureBsmlFont() async {
    if (_loadedFamilies.contains(bsmlFamily)) return bsmlFamily;

    if (_loading.contains(bsmlFamily)) {
      while (_loading.contains(bsmlFamily)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return bsmlFamily;
    }

    _loading.add(bsmlFamily);
    try {
      final loader = FontLoader(bsmlFamily);
      loader.addFont(_loadFromAsset('assets/fonts/QCF_BSML.TTF'));
      await loader.load();
      _loadedFamilies.add(bsmlFamily);
    } finally {
      _loading.remove(bsmlFamily);
    }
    return bsmlFamily;
  }

  /// Families that ship as assets but are registered only when a screen that
  /// needs them appears. Declaring them under pubspec's `fonts:` made the
  /// engine fetch all of them during startup — around 1.4 MB the home screen
  /// never draws with.
  static const Map<String, String> deferredFamilies = {
    'Amiri': 'assets/fonts/Amiri-Regular.ttf',
    'AmiriQuran': 'assets/fonts/AmiriQuran-Regular.ttf',
    'Scheherazade': 'assets/fonts/ScheherazadeNew-Regular.ttf',
    'Lateef': 'assets/fonts/Lateef-Regular.ttf',
    'QuranTaha': 'assets/fonts/QuranTaha.ttf',
    'sura_names': 'assets/fonts/sura_names.ttf',
  };

  final Map<String, Future<void>> _familyLoads = <String, Future<void>>{};

  /// Registers one of [deferredFamilies], once. Safe to call on every build:
  /// repeat calls return the in-flight or completed future.
  ///
  /// Loading a font clears Flutter's text layout cache, so text already on
  /// screen in a fallback face repaints itself in the real one as soon as this
  /// completes — callers only need to await it where a fallback would be
  /// unreadable, as it is for the glyph-mapped families.
  Future<void> ensureFamily(String family) {
    final asset = deferredFamilies[family];
    if (asset == null) return Future<void>.value();
    return _familyLoads.putIfAbsent(family, () async {
      try {
        final loader = FontLoader(family);
        loader.addFont(_loadFromAsset(asset));
        await loader.load();
      } catch (e) {
        _familyLoads.remove(family); // let a later attempt retry
        log('QcfFont: could not load $family — $e');
        rethrow;
      }
    });
  }

  Future<void> preloadAdjacent(int pageNo, {int totalPages = 604}) async {
    final neighbours = <int>[
      if (pageNo > 1) pageNo - 1,
      if (pageNo < totalPages) pageNo + 1,
    ];
    await Future.wait(
      neighbours.map((p) async {
        try {
          await ensurePageFont(p);
        } on FontNotInstalledError {
          // Expected for preview-only installs
        }
      }),
      eagerError: false,
    );
  }

  Future<bool> isFontAvailable(int pageNo) async {
    if (_bundledPages.contains(pageNo)) return true;
    if (kIsWeb) {
      return MushafFontStore.hasFont('QCF_P${_pad(pageNo)}.TTF');
    }
    final file = await _localFile(pageNo);
    return file != null && file.existsSync() && (await file.length()) > 1000;
  }

  Future<ByteData> _resolveFontBytes(int pageNo) async {
    if (kIsWeb) {
      // Try IndexedDB-backed store first (populated after download).
      final bytes = await MushafFontStore.loadFont('QCF_P${_pad(pageNo)}.TTF');
      if (bytes != null) return ByteData.sublistView(bytes);
    } else {
      final local = await _localFile(pageNo);
      if (local != null && await local.exists()) {
        final bytes = await local.readAsBytes();
        return ByteData.sublistView(bytes);
      }
    }

    if (_bundledPages.contains(pageNo)) {
      return await _loadFromAsset('assets/fonts/QCF_P${_pad(pageNo)}.TTF');
    }

    throw FontNotInstalledError(pageNo);
  }

  Future<File?> _localFile(int pageNo) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      return File('${docs.path}/mushaf_fonts/QCF_P${_pad(pageNo)}.TTF');
    } catch (_) {
      return null;
    }
  }

  static String _pad(int pageNo) {
    if (pageNo <= 2) return '$pageNo';
    if (pageNo < 10) return '00$pageNo';
    if (pageNo < 100) return '0$pageNo';
    return '$pageNo';
  }

  Future<ByteData> _loadFromAsset(String path) async {
    try {
      return await rootBundle.load(path);
    } catch (_) {
      return rootBundle.load(path.replaceAll('.TTF', '.ttf'));
    }
  }
}
