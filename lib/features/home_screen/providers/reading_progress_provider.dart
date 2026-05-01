import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks per-surah ayah-level reading progress.
///
/// For each surah, stores the highest ayah number the user has scrolled to.
/// Overall progress = sum of all max-ayah-read / total Quran ayahs (6236).
class ReadingProgressProvider extends ChangeNotifier {
  static const _kProgressMap = 'reading_progress_map';
  static const _kTotalMap = 'reading_total_map';
  static const int totalQuranAyahs = 6236;

  /// surahNumber → highest ayah number read.
  Map<int, int> _progressMap = {};

  /// surahNumber → total ayahs in that surah (from the database).
  Map<int, int> _totalMap = {};

  /// Max ayah read in a specific surah.
  int maxAyahRead(int surahNumber) => _progressMap[surahNumber] ?? 0;

  /// Total ayahs stored for a surah.
  int totalForSurah(int surahNumber) => _totalMap[surahNumber] ?? 0;

  /// Total number of ayahs read across all surahs.
  int get totalAyahsRead {
    int sum = 0;
    for (final entry in _progressMap.entries) {
      sum += entry.value;
    }
    return sum;
  }

  /// 0.0 – 1.0 fraction of Quran completed.
  double get progress =>
      totalQuranAyahs > 0 ? totalAyahsRead / totalQuranAyahs : 0.0;

  /// Percentage string (e.g. "15%").
  String get progressPercent => '${(progress * 100).toStringAsFixed(0)}%';

  /// Whether a surah is fully read.
  bool isSurahComplete(int surahNumber) {
    final total = _totalMap[surahNumber];
    if (total == null || total <= 0) return false;
    return (_progressMap[surahNumber] ?? 0) >= total;
  }

  /// Progress within a single surah (0.0 – 1.0).
  double surahProgress(int surahNumber) {
    final total = _totalMap[surahNumber];
    if (total == null || total <= 0) return 0.0;
    final read = _progressMap[surahNumber] ?? 0;
    return (read / total).clamp(0.0, 1.0);
  }

  ReadingProgressProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final progressJson = prefs.getString(_kProgressMap);
      if (progressJson != null) {
        final decoded = jsonDecode(progressJson) as Map<String, dynamic>;
        _progressMap = decoded.map(
          (key, value) => MapEntry(int.parse(key), value as int),
        );
      }
      final totalJson = prefs.getString(_kTotalMap);
      if (totalJson != null) {
        final decoded = jsonDecode(totalJson) as Map<String, dynamic>;
        _totalMap = decoded.map(
          (key, value) => MapEntry(int.parse(key), value as int),
        );
      }
    } catch (e) {
      debugPrint('ReadingProgressProvider: load failed — $e');
      // Keep any previously loaded data instead of resetting to empty.
    }
    notifyListeners();
  }

  /// Updates progress for a surah to reflect the current reading position.
  /// [totalAyahs] is the actual ayah count from the database for this surah.
  Future<void> updateProgress({
    required int surahNumber,
    required int ayahNumber,
    required int totalAyahs,
  }) async {
    if (surahNumber < 1 || totalAyahs <= 0) return;

    _totalMap[surahNumber] = totalAyahs;

    final clamped = ayahNumber.clamp(1, totalAyahs);
    final current = _progressMap[surahNumber] ?? 0;
    if (clamped == current) {
      await _save();
      return;
    }

    _progressMap[surahNumber] = clamped;
    notifyListeners();
    await _save();
  }

  /// Resets all progress.
  Future<void> resetProgress() async {
    _progressMap.clear();
    _totalMap.clear();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedProgress = jsonEncode(
      _progressMap.map((key, value) => MapEntry(key.toString(), value)),
    );
    final encodedTotal = jsonEncode(
      _totalMap.map((key, value) => MapEntry(key.toString(), value)),
    );
    await prefs.setString(_kProgressMap, encodedProgress);
    await prefs.setString(_kTotalMap, encodedTotal);
  }
}
