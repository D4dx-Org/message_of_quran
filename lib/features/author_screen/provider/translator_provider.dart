import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/about_author_model.dart';
import 'package:the_message_of_the_quran/core/services/database/about_author_db_helper.dart';

class TranslatorProvider extends ChangeNotifier {
  List<AboutAuthorModel> aboutAuthorList = [];
  bool isLoading = false;

  Future<void> getAboutAuthorInfo() async {
    isLoading = true;
    notifyListeners();
    aboutAuthorList = await AboutAuthorDbHelper.getAboutAuthor();
    isLoading = false;
    notifyListeners();
  }
}
