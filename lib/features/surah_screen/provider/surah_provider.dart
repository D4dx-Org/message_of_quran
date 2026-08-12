import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_model.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/core/services/database/arabic_block_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/bookmark_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/database_ready_notifier.dart';
import 'package:the_message_of_the_quran/core/services/database/interpretations_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/surah_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/translation_block_db_helper.dart';
import 'package:the_message_of_the_quran/features/mushaf/data/mushaf_repository.dart';
import 'package:the_message_of_the_quran/features/mushaf/utils/mushaf_text_utils.dart';

class SurahProvider extends ChangeNotifier {
  static const String _rtlEmbeddingStart = '\u202B';
  static const String _rtlEmbeddingEnd = '\u202C';
  static const String _rtlParagraphMark = '\u200F';
  static final RegExp _legacyTranslationPrefixRegex = RegExp(
    r'^[\d,\-]+[\s.]*',
  );
  static final RegExp _arabicLetterRegex = RegExp(
    r'[\u0621-\u064A\u066E-\u06D3\u06FA-\u06FF]',
  );
  static final RegExp _translationMarkerRegex = RegExp(
    r'﴿[\u0660-\u06690-9]+﴾',
  );

  ////////////////////////////////// Variables //////////////////////////////////

  bool _isDisposed = false;

  List<SurahModel> surahList = [];
  List<InterpretationModel> interpretationList = [];
  List<int> currentInterpretationAyahNumbers = [];
  int currentInterpretationNumber = -1;
  int minInterpretationNumber = -1;
  int maxInterpretationNumber = -1;

  /// Footnotes are stored with the number the source file uses, which does not
  /// always start at 1 for a surah — the Malayalam surah 1 notes run 6-9,
  /// because 1-5 are the translator's introduction notes that no verse refers
  /// to. Markers are shown as `number - noteNumberBase + 1` so a reader sees
  /// 1, 2, 3… while lookups keep using the stored number.
  int noteNumberBase = 1;

  int displayNoteNumber(int storedNumber) =>
      storedNumber - noteNumberBase + 1 > 0
      ? storedNumber - noteNumberBase + 1
      : storedNumber;
  int index = 0;
  TextEditingController searchController = TextEditingController();
  final List<AyahBookmarkModel> bookmarkedList = [];
  final List<SurahModel> searchList = [];
  bool isSearched = false;
  bool isSurahLoading = false;
  List<ArabicBlockModel> arabicBlockList = [];
  List<TranslationBlockModel> translationBlockList = [];
  String currentBismillahGlyph = '';
  bool _isSwiping = false;

  // ── Language state ──
  bool _isMalayalam = false;
  bool get isMalayalam => _isMalayalam;

  /// Called when language changes. Reloads all content.
  Future<void> setMalayalam(bool value) async {
    if (_isMalayalam == value) return;
    _isMalayalam = value;
    surahList = [];
    await getAllSurah();
    if (surahList.isNotEmpty && index >= 0 && index < surahList.length) {
      await getAyasForCurrentSurah();
    }
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

  String _cleanTranslationText(String text) {
    return text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  String _stripLegacyTranslationPrefix(String text) {
    return text.replaceFirst(_legacyTranslationPrefixRegex, '').trim();
  }

  List<String> _legacyTranslationSentences(String text) {
    final parts = text.split('. ');
    final sentences = <String>[];
    for (int index = 0; index < parts.length; index++) {
      var sentence = parts[index].trim();
      if (sentence.isEmpty) continue;
      if (index < parts.length - 1 && !sentence.endsWith('.')) {
        sentence = '$sentence.';
      }
      sentences.add(sentence);
    }
    return sentences;
  }

  String _extractTranslationFromMarkerBlock(
    String blockText,
    int verseFrom,
    int targetAyah,
  ) {
    final matches = _translationMarkerRegex.allMatches(blockText).toList();
    if (matches.isEmpty) return '';

    var currentAyah = verseFrom;
    var start = 0;
    for (final match in matches) {
      final segment = blockText.substring(start, match.end).trim();
      if (currentAyah == targetAyah && segment.isNotEmpty) {
        return segment;
      }
      start = match.end;
      currentAyah++;
    }

    if (start < blockText.length && currentAyah == targetAyah) {
      return blockText.substring(start).trim();
    }

    return '';
  }

  String _extractTranslationFromLegacyText({
    required String text,
    required int verseFrom,
    required int verseTo,
    required int targetAyah,
  }) {
    final cleaned = _cleanTranslationText(text);
    if (cleaned.isEmpty) return '';

    final withoutPrefix = _stripLegacyTranslationPrefix(cleaned);
    if (withoutPrefix.isEmpty) return '';

    final markerBased = _extractTranslationFromMarkerBlock(
      withoutPrefix,
      verseFrom,
      targetAyah,
    );
    if (markerBased.isNotEmpty) {
      return markerBased;
    }

    final sentences = _legacyTranslationSentences(withoutPrefix);
    final sentenceIndex = targetAyah - verseFrom;
    if (sentenceIndex >= 0 && sentenceIndex < sentences.length) {
      return sentences[sentenceIndex];
    }

    if (verseFrom == verseTo || targetAyah == verseFrom) {
      return withoutPrefix;
    }

    return '';
  }

  String _arabicTextForAyah(int ayahNumber) {
    for (final block in arabicBlockList) {
      if (block.verseFrom == ayahNumber) {
        return (block.arabicText ?? '').trim();
      }
    }
    return '';
  }

  String _formatArabicTextForExport(String text) {
    if (text.isEmpty || !_arabicLetterRegex.hasMatch(text)) {
      return text;
    }
    return '$_rtlParagraphMark$_rtlEmbeddingStart$text$_rtlEmbeddingEnd$_rtlParagraphMark';
  }

  String _translationTextForAyah(int ayahNumber) {
    TranslationBlockModel? directMatch;
    final rangedMatches = <TranslationBlockModel>[];

    for (final block in translationBlockList) {
      final from = block.verseFrom ?? 0;
      final to = block.verseTo ?? from;
      if (ayahNumber < from || ayahNumber > to) continue;

      if (from == ayahNumber && to == ayahNumber) {
        directMatch ??= block;
      } else {
        rangedMatches.add(block);
      }
    }

    if (directMatch != null) {
      return _stripLegacyTranslationPrefix(
        _cleanTranslationText(directMatch.translationText ?? ''),
      );
    }

    if (rangedMatches.isEmpty) return '';

    if (rangedMatches.length == 1) {
      final block = rangedMatches.single;
      return _extractTranslationFromLegacyText(
        text: block.translationText ?? '',
        verseFrom: block.verseFrom ?? ayahNumber,
        verseTo: block.verseTo ?? ayahNumber,
        targetAyah: ayahNumber,
      );
    }

    final combinedText = rangedMatches
        .map((block) => _cleanTranslationText(block.translationText ?? ''))
        .where((text) => text.isNotEmpty)
        .join(' ')
        .trim();
    if (combinedText.isEmpty) return '';

    return _extractTranslationFromLegacyText(
      text: combinedText,
      verseFrom: rangedMatches.first.verseFrom ?? ayahNumber,
      verseTo: rangedMatches.last.verseTo ?? ayahNumber,
      targetAyah: ayahNumber,
    );
  }

  String _surahNameForExport() {
    if (surahList.isEmpty || index < 0 || index >= surahList.length) {
      return '';
    }
    return surahList[index].name;
  }

  String _buildAyahExportText(Iterable<int> ayahNumbers) {
    final sorted = ayahNumbers.toSet().toList()..sort();
    if (sorted.isEmpty) return '';

    final buffer = StringBuffer();
    final surahName = _surahNameForExport();
    if (surahName.isNotEmpty) {
      buffer.writeln(surahName);
      buffer.writeln();
    }

    for (int index = 0; index < sorted.length; index++) {
      final ayahNumber = sorted[index];
      final arabicText = _arabicTextForAyah(ayahNumber);
      final translationText = _translationTextForAyah(ayahNumber);

      if (index > 0) {
        buffer.writeln();
      }

      buffer.writeln('Ayah $ayahNumber');
      if (arabicText.isNotEmpty) {
        buffer.writeln(_formatArabicTextForExport(arabicText));
      }
      if (translationText.isNotEmpty) {
        if (arabicText.isNotEmpty) {
          buffer.writeln();
        }
        buffer.writeln(translationText);
      }
    }

    buffer.writeln();
    final iOSLine = AppConstants.iosStoreUrl.isEmpty
      ? 'iOS :'
      : 'iOS : ${AppConstants.iosStoreUrl}';
    buffer.writeln('Source : ${AppConstants.appName}');
    buffer.writeln('Android : ${AppConstants.androidStoreUrl}');
    buffer.writeln(iOSLine);
    buffer.writeln('powered by : D4DX Innovations');
    return buffer.toString().trimRight();
  }

  String getAyahText(int ayahNumber) {
    return _buildAyahExportText([ayahNumber]);
  }

  String getSelectedText() {
    return _buildAyahExportText(_selectedAyahs);
  }

  DatabaseReadyNotifier? _dbNotifier;

  SurahProvider({DatabaseReadyNotifier? dbNotifier}) {
    // Defer until after the first frame so notifyListeners() is never called
    // while the widget tree is locked (during the initial build), which would
    // throw: "setState() or markNeedsBuild() called when widget tree was locked."
    WidgetsBinding.instance.addPostFrameCallback((_) => loadBookmarks());

    // On web, MyApp (and this provider) is built before the database finishes
    // loading, so the call above can run against an unopened userDatabase.
    // Re-run it once the database becomes ready.
    if (dbNotifier != null && dbNotifier.status != DbInitStatus.ready) {
      _dbNotifier = dbNotifier;
      dbNotifier.addListener(_onDbReady);
    }
  }

  void _onDbReady() {
    if (_dbNotifier?.status != DbInitStatus.ready) return;
    _dbNotifier?.removeListener(_onDbReady);
    _dbNotifier = null;
    loadBookmarks();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dbNotifier?.removeListener(_onDbReady);
    _singleTapTimer?.cancel();
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
    currentInterpretationAyahNumbers.clear();
    currentInterpretationNumber = -1;
    minInterpretationNumber = -1;
    maxInterpretationNumber = -1;
    noteNumberBase = 1;
  }

  void assignIndex(int indexClicked) {
    index = indexClicked;
    arabicBlockList = [];
    translationBlockList = [];
    _clearCurrentBismillahGlyph();
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
      _clearCurrentBismillahGlyph();
      notifyListeners();
      await getAyasForCurrentSurah();
    } finally {
      _isSwiping = false;
    }
  }

  bool _shouldShowDecorativeBismillah(int surahNumber) {
    return surahNumber > 0 && surahNumber != 1 && surahNumber != 9;
  }

  void _clearCurrentBismillahGlyph() {
    currentBismillahGlyph = '';
  }

  Future<String> _loadCurrentBismillahGlyph(int surahNumber) async {
    if (!_shouldShowDecorativeBismillah(surahNumber)) {
      return '';
    }

    try {
      final rawGlyph = await MushafRepository().getBismillahGlyph(3);
      if (rawGlyph.isEmpty) {
        return '';
      }
      final segments = MushafTextUtils.parseLine(
        rawGlyph,
        isHeadingOrBismillah: true,
      );
      return segments.isNotEmpty ? segments.first.text : '';
    } catch (_) {
      return '';
    }
  }
  ///////////////////////////////// bookmarks /////////////////////////////////

  AyahBookmarkModel? getBookmark(
    int surahNumber,
    int ayahId, {
    String navigationTarget = BookmarkNavigationTarget.surah,
  }) {
    final normalizedTarget = BookmarkNavigationTarget.normalize(
      navigationTarget,
    );
    for (final bookmark in bookmarkedList) {
      if (bookmark.surahNumber == surahNumber &&
          bookmark.ayahId == ayahId &&
          bookmark.navigationTarget == normalizedTarget) {
        return bookmark;
      }
    }
    return null;
  }

  List<AyahBookmarkModel> getBookmarksForSurah(
    int surahNumber, {
    required String navigationTarget,
  }) {
    final normalizedTarget = BookmarkNavigationTarget.normalize(
      navigationTarget,
    );
    return bookmarkedList.where((bookmark) {
      return bookmark.surahNumber == surahNumber &&
          bookmark.navigationTarget == normalizedTarget;
    }).toList();
  }

  bool hasSurahBookmarkConflict(
    int surahNumber,
    int ayahId, {
    required String navigationTarget,
  }) {
    final bookmarks = getBookmarksForSurah(
      surahNumber,
      navigationTarget: navigationTarget,
    );
    if (bookmarks.isEmpty) return false;
    return bookmarks.any((bookmark) => bookmark.ayahId != ayahId);
  }

  bool isAyahBookmarked(
    int surahNumber,
    int ayahId, {
    String navigationTarget = BookmarkNavigationTarget.surah,
  }) {
    return getBookmark(
          surahNumber,
          ayahId,
          navigationTarget: navigationTarget,
        ) !=
        null;
  }

  bool isAyahBookmarkedForTarget(
    int surahNumber,
    int ayahId,
    String navigationTarget,
  ) {
    return isAyahBookmarked(
      surahNumber,
      ayahId,
      navigationTarget: navigationTarget,
    );
  }

  Future<bool> onBookMarkAdd(
    int surahNumber,
    int ayahId, {
    String? surahName,
    String? ayaText,
    String? surahArabicName,
    String? surahArabicNumber,
    String? navigationTarget,
    bool replaceSameSurah = false,
  }) async {
    final normalizedTarget = BookmarkNavigationTarget.normalize(
      navigationTarget,
    );
    final existingBookmark = getBookmark(
      surahNumber,
      ayahId,
      navigationTarget: normalizedTarget,
    );
    if (existingBookmark != null) {
      return false;
    }

    final sameSurahBookmarks = getBookmarksForSurah(
      surahNumber,
      navigationTarget: normalizedTarget,
    );
    final metadataSource = sameSurahBookmarks.isNotEmpty
        ? sameSurahBookmarks.first
        : null;

    final bookmark = AyahBookmarkModel(
      surahNumber: surahNumber,
      ayahId: ayahId,
      surahName: surahName ?? metadataSource?.surahName,
      ayaText: ayaText ?? metadataSource?.ayaText,
      surahArabicName: surahArabicName ?? metadataSource?.surahArabicName,
      surahArabicNumber: surahArabicNumber ?? metadataSource?.surahArabicNumber,
      navigationTarget: normalizedTarget,
    );
    try {
      if (replaceSameSurah && sameSurahBookmarks.isNotEmpty) {
        await BookmarkDbHelper.deleteBySurah(
          surahNumber,
          navigationTarget: normalizedTarget,
        );
        bookmarkedList.removeWhere(
          (bookmark) =>
              bookmark.surahNumber == surahNumber &&
              bookmark.navigationTarget == normalizedTarget,
        );
      }

      await BookmarkDbHelper.insert(bookmark);
      bookmarkedList.removeWhere(
        (b) =>
            b.surahNumber == surahNumber &&
            b.ayahId == ayahId &&
            b.navigationTarget == normalizedTarget,
      );
      bookmarkedList.insert(0, bookmark);
      notifyListeners();
      return true;
    } catch (e) {
      // don't add to list if DB insert failed
      return false;
    }
  }

  Future<void> onBookMarkRemoveByAyah(
    int surahNumber,
    int ayahId, {
    String navigationTarget = BookmarkNavigationTarget.surah,
  }) async {
    final normalizedTarget = BookmarkNavigationTarget.normalize(
      navigationTarget,
    );
    try {
      await BookmarkDbHelper.deleteBySurahAndAyah(
        surahNumber,
        ayahId,
        navigationTarget: normalizedTarget,
      );
      bookmarkedList.removeWhere(
        (b) =>
            b.surahNumber == surahNumber &&
            b.ayahId == ayahId &&
            b.navigationTarget == normalizedTarget,
      );
      notifyListeners();
    } catch (e) {
      // keep list in sync on error
    }
  }

  Future<void> updateBookmarkLabel(
    int surahNumber,
    int ayahId,
    String? label, {
    String navigationTarget = BookmarkNavigationTarget.surah,
  }) async {
    final normalizedTarget = BookmarkNavigationTarget.normalize(
      navigationTarget,
    );
    try {
      await BookmarkDbHelper.updateLabel(
        surahNumber,
        ayahId,
        label,
        navigationTarget: normalizedTarget,
      );
      final idx = bookmarkedList.indexWhere(
        (b) =>
            b.surahNumber == surahNumber &&
            b.ayahId == ayahId &&
            b.navigationTarget == normalizedTarget,
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
          navigationTarget: normalizedTarget,
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
    if (surahList.isEmpty) {
      await getAllSurah();
    } else {
      // Force an async gap even on the already-loaded fast path, so the
      // notifyListeners() below never fires synchronously with a caller's
      // build phase (e.g. SurahRouteResolver.initState), which would throw
      // "setState() called during build".
      await Future<void>.value();
    }
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
        navigationTarget: item.navigationTarget,
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
        // Opening a note resets the interpretation state, so the display base
        // has to be restored here too, not only when the surah loads.
        noteNumberBase = minInterpretationNumber > 0
            ? minInterpretationNumber
            : 1;
      }
      currentInterpretationNumber = interpretationNumber;
      interpretationList = await InterpretationsDbHelper.getinterpretations(
        surahNumber: surahList[index].surahNumber,
        interpretationNumber: interpretationNumber,
        malayalam: _isMalayalam,
      );
      currentInterpretationAyahNumbers =
          await TranslationBlockDbHelper.getVerseNumbersForFootnote(
            surahList[index].surahNumber,
            interpretationNumber,
            malayalam: _isMalayalam,
          );
    } catch (e) {
      interpretationList = [];
      currentInterpretationAyahNumbers = [];
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
      _clearCurrentBismillahGlyph();
      notifyListeners();
      return;
    }
    final surahNumber = surahList[index].surahNumber;
    try {
      final results = await Future.wait<dynamic>([
        ArabicBlockDbHelper.getArabicBlocksBySurah(surahNumber),
        TranslationBlockDbHelper.getTranslationBlocksBySurah(
          surahNumber,
          malayalam: _isMalayalam,
        ),
        _loadCurrentBismillahGlyph(surahNumber),
        // Needed before the first marker is painted, so it is fetched with the
        // verses rather than lazily when a note is opened.
        InterpretationsDbHelper.getInterpretationRange(
          surahNumber: surahNumber,
          malayalam: _isMalayalam,
        ),
      ]);
      arabicBlockList = results[0] as List<ArabicBlockModel>;
      translationBlockList = results[1] as List<TranslationBlockModel>;
      currentBismillahGlyph = results[2] as String;

      final range = results[3] as Map<String, int>;
      minInterpretationNumber = range['min'] ?? -1;
      maxInterpretationNumber = range['max'] ?? -1;
      noteNumberBase = minInterpretationNumber > 0 ? minInterpretationNumber : 1;
    } catch (e) {
      arabicBlockList = [];
      translationBlockList = [];
      _clearCurrentBismillahGlyph();
    } finally {
      notifyListeners();
    }
  }
}
