import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/models/favorite_surah_model.dart';

/// Favourites are stored in SharedPreferences (backed by localStorage on
/// web) rather than the sqflite user database — the web sqlite database
/// lives in IndexedDB via a wasm worker, which was losing writes across a
/// page refresh. localStorage is synchronous and durable, so it doesn't
/// have that failure mode.
class FavoriteSurahDbHelper {
  static const String _prefsKey = 'favorite_surahs_v1';

  static Future<List<FavoriteSurahModel>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      final models = decoded
          .map((e) => FavoriteSurahModel.fromMap(e as Map<String, dynamic>))
          .toList();
      models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return models;
    } catch (e) {
      debugPrint('FavoriteSurahDbHelper: getAll failed — $e');
      return [];
    }
  }

  static Future<void> add(int surahNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getAll();
      final withoutExisting =
          current.where((m) => m.surahNumber != surahNumber).toList();
      withoutExisting.insert(
        0,
        FavoriteSurahModel(
          surahNumber: surahNumber,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await prefs.setString(
        _prefsKey,
        jsonEncode(withoutExisting.map((m) => m.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('FavoriteSurahDbHelper: add failed — $e');
    }
  }

  static Future<void> remove(int surahNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getAll();
      final remaining =
          current.where((m) => m.surahNumber != surahNumber).toList();
      await prefs.setString(
        _prefsKey,
        jsonEncode(remaining.map((m) => m.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('FavoriteSurahDbHelper: remove failed — $e');
    }
  }
}
