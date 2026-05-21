import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/translator_note_model.dart';
import 'package:the_message_of_the_quran/core/services/database/translator_note_db_helper.dart';

class TranslatorNoteProvider extends ChangeNotifier {
  List<TranslatorNoteModel> translatorNoteList = [];
  bool isLoading = false;

  Future<void> getTranslatorNoteInfo() async {
    isLoading = true;
    notifyListeners();
    translatorNoteList = await TranslatorNoteDbHelper.getTranslatorNotes();
    isLoading = false;
    notifyListeners();
  }
}
