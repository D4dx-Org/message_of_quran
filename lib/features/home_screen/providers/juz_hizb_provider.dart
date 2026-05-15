import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/juz_hizb_model.dart';
import 'package:the_message_of_the_quran/core/services/database/juz_hizb_db_helper.dart';

class JuzHizbProvider extends ChangeNotifier {
  List<JuzHizbModel> juzList = [];
  List<JuzHizbModel> hizbList = [];
  bool isLoading = false;

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
