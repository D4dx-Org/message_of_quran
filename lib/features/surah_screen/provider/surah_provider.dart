import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_model.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/core/services/database/arabic_block_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/bookmark_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/interpretations_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/surah_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/translation_block_db_helper.dart';

class SurahProvider extends ChangeNotifier {
  ////////////////////////////////// Variables //////////////////////////////////

  List<SurahModel> surahList = [];
  List<InterpretationModel> interpretationList = [];
  int currentInterpretationNumber = -1;
  int minInterpretationNumber = -1;
  int maxInterpretationNumber = -1;
  int index = 0;
  TextEditingController searchController = TextEditingController();
  final List<AyahBookmarkModel> bookmarkedList = [];
  final List<SurahModel> searchList = [];
  bool isSearched = false;
  bool isSurahLoading = false;
  List<ArabicBlockModel> arabicBlockList = [];
  List<TranslationBlockModel> translationBlockList = [];
  bool _isSwiping = false;

  // ── Language state ──
  bool _isMalayalam = false;
  bool get isMalayalam => _isMalayalam;

  /// Called when language changes. Reloads all content.
  /// TODO: Re-enable when Malayalam DB is ready
  Future<void> setMalayalam(bool value) async {
    // No-op: Malayalam DB not available yet. Always use English data.
    // When Malayalam DB is ready, uncomment the block below.
    //
    // if (_isMalayalam == value) return;
    // _isMalayalam = value;
    // surahList = [];
    // await getAllSurah();
    // if (surahList.isNotEmpty && index >= 0 && index < surahList.length) {
    //   await getAyasForCurrentSurah();
    // }
  }

  // ── Ayah toggle-selection state (Set of individual ayah numbers) ──
  final Set<int> _selectedAyahs = {};

  // Double-tap detection for toggling selection.
  int? _lastTappedAyah;
  DateTime? _lastTapTime;
  Timer? _singleTapTimer;
  bool ayahTapHandled = false;

  bool get isSelectionActive => _selectedAyahs.isNotEmpty;

  int get selectionCount => _selectedAyahs.length;

  String get selectionLabel {
    if (_selectedAyahs.isEmpty) return '';
    final sorted = _selectedAyahs.toList()..sort();
    if (sorted.length == 1) return 'Ayah ${sorted.first} selected';
    return 'Ayah ${sorted.join(', ')} selected';
  }

  bool isAyahSelected(int ayahNumber) => _selectedAyahs.contains(ayahNumber);

  void toggleSelection(int ayahNumber) {
    if (_selectedAyahs.contains(ayahNumber)) {
      _selectedAyahs.remove(ayahNumber);
    } else {
      _selectedAyahs.add(ayahNumber);
    }
    notifyListeners();
  }

  /// Double-tap toggles that ayah in/out of selection.
  /// Single tap (after 400ms with no second tap) clears all selections.
  void onAyahTap(int ayahNumber) {
    ayahTapHandled = true;
    final now = DateTime.now();
    if (_lastTappedAyah == ayahNumber &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 400) {
      // Double-tap detected — cancel pending clear and toggle.
      _singleTapTimer?.cancel();
      _lastTappedAyah = null;
      _lastTapTime = null;
      toggleSelection(ayahNumber);
    } else {
      // First tap — wait to see if a second tap follows.
      _singleTapTimer?.cancel();
      _lastTappedAyah = ayahNumber;
      _lastTapTime = now;
      if (isSelectionActive) {
        _singleTapTimer = Timer(const Duration(milliseconds: 400), () {
          clearSelection();
        });
      }
    }
  }

  void clearSelection() {
    if (_selectedAyahs.isEmpty) return;
    _selectedAyahs.clear();
    notifyListeners();
  }

  String getSelectedText() {
    if (_selectedAyahs.isEmpty) return '';
    final sorted = _selectedAyahs.toList()..sort();

    final surahName =
        surahList.isNotEmpty && index >= 0 && index < surahList.length
        ? surahList[index].name
        : '';
    final buffer = StringBuffer();
    if (surahName.isNotEmpty) {
      buffer.writeln(surahName);
      buffer.writeln();
    }

    // Collect per-ayah Arabic text.
    for (int i = 0; i < sorted.length; i++) {
      final ayah = sorted[i];
      String? ayahArabic;
      for (final block in arabicBlockList) {
        if (block.verseFrom == ayah) {
          ayahArabic = block.arabicText;
          break;
        }
      }

      buffer.writeln('Ayah $ayah');
      if (ayahArabic != null && ayahArabic.isNotEmpty) {
        buffer.writeln(ayahArabic.trim());
      }
      if (i < sorted.length - 1) buffer.writeln();
    }

    // Match translations per-ayah by grouping rows and mapping to ayahs.
    final allLo = sorted.first;
    final allHi = sorted.last;
    final relevantTranslations = translationBlockList.where((b) {
      final from = b.verseFrom ?? 0;
      final to = b.verseTo ?? 0;
      return from <= allHi && to >= allLo;
    }).toList();

    // Group by leading digit (same logic as the UI).
    final tGroups = <List<TranslationBlockModel>>[];
    for (final block in relevantTranslations) {
      final preview = (block.translationText ?? '')
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '')
          .trim();
      if (tGroups.isEmpty || RegExp(r'^\d').hasMatch(preview)) {
        tGroups.add([block]);
      } else {
        tGroups.last.add(block);
      }
    }

    final prefixRegex = RegExp(r'^[\d,\-]+[\s.]*');
    for (final group in tGroups) {
      final firstText = (group.first.translationText ?? '')
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '')
          .trim();
      final rangeMatch = RegExp(r'^([\d,\-]+)').firstMatch(firstText);
      if (rangeMatch == null) continue;
      final rangeStr = rangeMatch.group(1)!;
      int gLo, gHi;
      if (rangeStr.contains('-')) {
        final parts = rangeStr.split('-');
        gLo = int.tryParse(parts.first) ?? 0;
        gHi = int.tryParse(parts.last) ?? gLo;
      } else if (rangeStr.contains(',')) {
        final nums = rangeStr
            .split(',')
            .map((s) => int.tryParse(s.trim()) ?? 0)
            .toList();
        gLo = nums.reduce((a, b) => a < b ? a : b);
        gHi = nums.reduce((a, b) => a > b ? a : b);
      } else {
        gLo = int.tryParse(rangeStr) ?? 0;
        gHi = gLo;
      }
      // Skip group if none of the selected ayahs fall within it.
      final groupHasSelected = sorted.any((a) => a >= gLo && a <= gHi);
      if (!groupHasSelected) continue;
      final ayahCount = gHi - gLo + 1;

      // Build per-ayah sentences: split each row by '. ' then flatten.
      final sentences = <String>[];
      for (int r = 0; r < group.length; r++) {
        var rowText = (group[r].translationText ?? '')
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '')
            .trim();
        if (r == 0) rowText = rowText.replaceFirst(prefixRegex, '').trim();
        final parts = rowText.split('. ');
        for (int p = 0; p < parts.length; p++) {
          var s = parts[p].trim();
          if (p < parts.length - 1 && s.isNotEmpty && !s.endsWith('.')) {
            s = '$s.';
          }
          if (s.isNotEmpty) sentences.add(s);
        }
      }

      // Map sentences to ayahs and pick only the selected ones.
      if (sentences.length >= ayahCount) {
        for (int a = gLo; a <= gHi; a++) {
          if (_selectedAyahs.contains(a)) {
            final idx = a - gLo;
            if (idx < sentences.length) {
              buffer.writeln(sentences[idx]);
            }
          }
        }
      } else {
        for (final s in sentences) {
          buffer.writeln(s);
        }
      }
    }
    buffer.writeln();
    buffer.writeln('Source : The Message of the Quran');
    buffer.writeln(
      'Android : https://play.google.com/store/apps/details?id=com.d4dx.quran',
    );
    buffer.writeln(
      'iOS : https://apps.apple.com/us/app/vishudha-quran/id6761527985',
    );
    return buffer.toString().trimRight();
  }

  SurahProvider() {
    // Defer until after the first frame so notifyListeners() is never called
    // while the widget tree is locked (during the initial build), which would
    // throw: "setState() or markNeedsBuild() called when widget tree was locked."
    WidgetsBinding.instance.addPostFrameCallback((_) => loadBookmarks());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  ////////////////////////////////// Functions //////////////////////////////////

  Future<void> loadBookmarks() async {
    try {
      final result = await BookmarkDbHelper.getAllBookMarks();
      bookmarkedList.clear();
      bookmarkedList.addAll(result);
      notifyListeners();
    } catch (e) {
      // keep existing list on error
    }
  }

  void _resetInterpretationState() {
    interpretationList.clear();
    currentInterpretationNumber = -1;
    minInterpretationNumber = -1;
    maxInterpretationNumber = -1;
  }

  void assignIndex(int indexClicked) {
    index = indexClicked;
    arabicBlockList = [];
    translationBlockList = [];
    _resetInterpretationState();
    _selectedAyahs.clear();
    notifyListeners();
  }

  Future<void> getAllSurah() async {
    if (surahList.isNotEmpty) return;
    isSurahLoading = true;

    try {
      surahList = await SurahDbHelper.getAllSuras(malayalam: _isMalayalam);
    } catch (e) {
      surahList = [];
    } finally {
      isSurahLoading = false;
      notifyListeners();
    }
  }

  Future<void> onSwipe(bool isLeft) async {
    if (_isSwiping) return;
    _isSwiping = true;
    clearSelection();
    try {
      if (isLeft) {
        if (index == 0) return;
        index--;
      } else {
        if (index == surahList.length - 1) return;
        index++;
      }
      _resetInterpretationState();
      // Clear old data immediately so the scroll view is torn down and
      // recreated fresh at offset 0 when the new data arrives.
      arabicBlockList = [];
      translationBlockList = [];
      notifyListeners();
      await getAyasForCurrentSurah();
    } finally {
      _isSwiping = false;
    }
  }
  ///////////////////////////////// bookmarks /////////////////////////////////

  AyahBookmarkModel? getBookmark(int surahNumber, int ayahId) {
    for (final bookmark in bookmarkedList) {
      if (bookmark.surahNumber == surahNumber && bookmark.ayahId == ayahId) {
        return bookmark;
      }
    }
    return null;
  }

  bool isAyahBookmarked(int surahNumber, int ayahId) {
    return getBookmark(surahNumber, ayahId) != null;
  }

  bool isAyahBookmarkedForTarget(
    int surahNumber,
    int ayahId,
    String navigationTarget,
  ) {
    final bookmark = getBookmark(surahNumber, ayahId);
    return bookmark?.navigationTarget == navigationTarget;
  }

  Future<void> onBookMarkAdd(
    int surahNumber,
    int ayahId, {
    String? surahName,
    String? ayaText,
    String? surahArabicName,
    String? surahArabicNumber,
    String? navigationTarget,
  }) async {
    final existingBookmark = getBookmark(surahNumber, ayahId);
    if (existingBookmark != null &&
        existingBookmark.navigationTarget == navigationTarget) {
      return;
    }
    final bookmark = AyahBookmarkModel(
      surahNumber: surahNumber,
      ayahId: ayahId,
      surahName: surahName ?? existingBookmark?.surahName,
      ayaText: ayaText ?? existingBookmark?.ayaText,
      surahArabicName: surahArabicName ?? existingBookmark?.surahArabicName,
      surahArabicNumber:
          surahArabicNumber ?? existingBookmark?.surahArabicNumber,
      label: existingBookmark?.label,
      navigationTarget: navigationTarget,
    );
    try {
      await BookmarkDbHelper.insert(bookmark);
      bookmarkedList.removeWhere(
        (b) => b.surahNumber == surahNumber && b.ayahId == ayahId,
      );
      bookmarkedList.insert(0, bookmark);
      notifyListeners();
    } catch (e) {
      // don't add to list if DB insert failed
    }
  }

  Future<void> onBookMarkRemoveByAyah(int surahNumber, int ayahId) async {
    try {
      await BookmarkDbHelper.deleteBySurahAndAyah(surahNumber, ayahId);
      bookmarkedList.removeWhere(
        (b) => b.surahNumber == surahNumber && b.ayahId == ayahId,
      );
      notifyListeners();
    } catch (e) {
      // keep list in sync on error
    }
  }

  Future<void> updateBookmarkLabel(
    int surahNumber,
    int ayahId,
    String? label,
  ) async {
    try {
      await BookmarkDbHelper.updateLabel(surahNumber, ayahId, label);
      final idx = bookmarkedList.indexWhere(
        (b) => b.surahNumber == surahNumber && b.ayahId == ayahId,
      );
      if (idx >= 0) {
        final old = bookmarkedList[idx];
        bookmarkedList[idx] = AyahBookmarkModel(
          surahNumber: old.surahNumber,
          ayahId: old.ayahId,
          surahName: old.surahName,
          ayaText: old.ayaText,
          surahArabicName: old.surahArabicName,
          surahArabicNumber: old.surahArabicNumber,
          label: label,
          navigationTarget: old.navigationTarget,
        );
        notifyListeners();
      }
    } catch (e) {
      // ignore
    }
  }

  /// Sets the current surah index by its surahNumber, loading the surah list
  /// first if it is empty, then pre-fetches translations and ayahs so that
  /// SurahScreen opens with data already available (no loading-indicator flash
  /// and reliable scroll-to-ayah on first frame).
  Future<void> selectSurahByNumber(int surahNumber) async {
    if (surahList.isEmpty) await getAllSurah();
    final idx = surahList.indexWhere((s) => s.surahNumber == surahNumber);
    if (idx < 0) return;
    index = idx;
    _resetInterpretationState();
    // Clear old data so the scroll view resets to offset 0.
    arabicBlockList = [];
    translationBlockList = [];
    notifyListeners();
    // Pre-load ayah data before the screen opens.
    await getAyasForCurrentSurah();
  }

  Future<void> onBookMarkRemoveByIndex(int index) async {
    if (index < 0 || index >= bookmarkedList.length) return;
    final item = bookmarkedList[index];
    try {
      await BookmarkDbHelper.deleteBySurahAndAyah(
        item.surahNumber,
        item.ayahId,
      );
      bookmarkedList.removeAt(index);
      notifyListeners();
    } catch (e) {
      // keep list on error
    }
  }

  ///////////////////////////////// search /////////////////////////////////

  void search() {
    isSearched = true;
    searchList.clear();
    if (searchController.text.trim().isEmpty) {
      isSearched = false;
      notifyListeners();
      return;
    }
    List<String> splittedName = searchController.text
        .trim()
        .toLowerCase()
        .split(" ");

    for (int i = 0; i < surahList.length; i++) {
      String surahName = surahList[i].searchName;
      if (searchController.text.trim().contains(" ")) {
        if (surahName.contains(splittedName[0]) &&
            surahName.contains(splittedName[splittedName.length - 1])) {
          searchList.add(surahList[i]);
        }
      } else {
        if (surahName.contains(searchController.text.trim().toLowerCase())) {
          searchList.add(surahList[i]);
        }
      }
    }
    notifyListeners();
  }

  void clear() {
    searchController.clear();
    search();
  }

  ///////////////////////////////// interpretations /////////////////////////////////

  Future<void> getInterpretations(int interpretationNumber) async {
    if (surahList.isEmpty || index < 0 || index >= surahList.length) return;
    try {
      if (minInterpretationNumber == -1 || maxInterpretationNumber == -1) {
        final range = await InterpretationsDbHelper.getInterpretationRange(
          surahNumber: surahList[index].surahNumber,
          malayalam: _isMalayalam,
        );
        minInterpretationNumber = range['min'] ?? -1;
        maxInterpretationNumber = range['max'] ?? -1;
      }
      currentInterpretationNumber = interpretationNumber;
      interpretationList = await InterpretationsDbHelper.getinterpretations(
        surahNumber: surahList[index].surahNumber,
        interpretationNumber: interpretationNumber,
        malayalam: _isMalayalam,
      );
    } catch (e) {
      interpretationList = [];
    }
    notifyListeners();
  }

  Future<void> navigateInterpretation(bool next) async {
    if (next) {
      if (currentInterpretationNumber >= maxInterpretationNumber) return;
      await getInterpretations(currentInterpretationNumber + 1);
    } else {
      if (currentInterpretationNumber <= minInterpretationNumber) return;
      await getInterpretations(currentInterpretationNumber - 1);
    }
  }

  /// Opens the interpretation page that contains [ayahNumber].
  /// Resets state first so the sheet can show a loading spinner immediately,
  /// then resolves the correct [interpretationNumber] for that ayah and loads.
  Future<void> getInterpretationsForAyah(int ayahNumber) async {
    if (surahList.isEmpty || index < 0 || index >= surahList.length) return;
    _resetInterpretationState();
    notifyListeners();
    final surahNum = surahList[index].surahNumber;
    int pageNumber =
        await InterpretationsDbHelper.getInterpretationNumberForAyah(
          surahNumber: surahNum,
          ayahNumber: ayahNumber,
          malayalam: _isMalayalam,
        );
    if (pageNumber == -1) pageNumber = 1;
    await getInterpretations(pageNumber);
  }

  /// Opens a specific interpretation page directly by [pageNumber].
  Future<void> getInterpretationsForPage(int pageNumber) async {
    if (surahList.isEmpty || index < 0 || index >= surahList.length) return;
    _resetInterpretationState();
    notifyListeners();
    await getInterpretations(pageNumber);
  }

  /// Ayas fetching for current surah

  Future<void> getAyasForCurrentSurah() async {
    if (surahList.isEmpty || index < 0 || index >= surahList.length) {
      arabicBlockList = [];
      translationBlockList = [];
      notifyListeners();
      return;
    }
    final surahNumber = surahList[index].surahNumber;
    try {
      final results = await Future.wait([
        ArabicBlockDbHelper.getArabicBlocksBySurah(surahNumber),
        TranslationBlockDbHelper.getTranslationBlocksBySurah(surahNumber, malayalam: _isMalayalam),
      ]);
      arabicBlockList = results[0] as List<ArabicBlockModel>;
      translationBlockList = results[1] as List<TranslationBlockModel>;
    } catch (e) {
      arabicBlockList = [];
      translationBlockList = [];
    } finally {
      notifyListeners();
    }
  }
}
