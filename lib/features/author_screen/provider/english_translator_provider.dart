import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/english_translator_model.dart';
import 'package:the_message_of_the_quran/core/services/database/english_translator_db_helper.dart';

class EnglishTranslatorProvider extends ChangeNotifier {
  List<EnglishTranslatorModel> translatorList = [];
  bool isLoading = false;

  Future<void> getTranslatorInfo() async {
    isLoading = true;
    notifyListeners();
    translatorList = await EnglishTranslatorDbHelper.getTranslator();
    isLoading = false;
    notifyListeners();
  }
}
