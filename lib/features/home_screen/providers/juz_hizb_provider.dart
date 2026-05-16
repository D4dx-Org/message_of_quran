import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/models/juz_hizb_model.dart';
import 'package:the_message_of_the_quran/core/services/database/juz_hizb_db_helper.dart';

class JuzHizbProvider extends ChangeNotifier {
  static const _kSelectedJuzNumber = 'selected_juz_number';

  List<JuzHizbModel> juzList = [];
  List<JuzHizbModel> hizbList = [];
  bool isLoading = false;
  int? selectedJuzNumber;

  JuzHizbProvider() {
    unawaited(restoreSelectedJuz());
  }

  Future<void> selectJuz(int juzNumber) async {
    if (selectedJuzNumber == juzNumber) return;

    selectedJuzNumber = juzNumber;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kSelectedJuzNumber, juzNumber);
    } catch (e) {
      debugPrint('JuzHizbProvider: selected Juz save failed - $e');
    }
  }

  Future<void> restoreSelectedJuz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      selectedJuzNumber = prefs.getInt(_kSelectedJuzNumber);
    } catch (e) {
      debugPrint('JuzHizbProvider: selected Juz load failed - $e');
    }

    notifyListeners();
  }

  Future<void> loadJuz() async {
    if (juzList.isNotEmpty) return;
    isLoading = true;
    notifyListeners();

    try {
      juzList = await JuzHizbDbHelper.getAllJuz();
    } catch (e) {
      debugPrint('JuzHizbProvider: juz load failed - $e');
      juzList = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    if (juzList.isNotEmpty && hizbList.isNotEmpty) return;
    isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        JuzHizbDbHelper.getAllJuz(),
        JuzHizbDbHelper.getAllHizb(),
      ]);
      juzList = results[0];
      hizbList = results[1];
    } catch (e) {
      debugPrint('JuzHizbProvider: load failed — $e');
      juzList = [];
      hizbList = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
