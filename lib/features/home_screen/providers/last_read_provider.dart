import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the last-read surah / ayah so the HomeScreenBanner
/// and any navigation can use it.
class LastReadProvider extends ChangeNotifier {
  static const _kSurahNumber = 'last_read_surah_number';
  static const _kSurahName = 'last_read_surah_name';
  static const _kAyahId = 'last_read_ayah_id';

  int? surahNumber;
  String? surahName;
  int? ayahId;

  bool get hasLastRead => surahNumber != null;

  LastReadProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      surahNumber = prefs.getInt(_kSurahNumber);
      surahName = prefs.getString(_kSurahName);
      ayahId = prefs.getInt(_kAyahId);
    } catch (e) {
      debugPrint('LastReadProvider: load failed — $e');
    }
    notifyListeners();
  }

  /// Call this whenever the user's reading position changes (on scroll stop,
  /// on swipe, and on screen exit).
  Future<void> saveLastRead({
    required int surahNumber,
    required String surahName,
    required int ayahId,
  }) async {
    this.surahNumber = surahNumber;
    this.surahName = surahName;
    this.ayahId = ayahId;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kSurahNumber, surahNumber);
      await prefs.setString(_kSurahName, surahName);
      await prefs.setInt(_kAyahId, ayahId);
    } catch (e) {
      debugPrint('LastReadProvider: save failed — $e');
    }
  }
}
