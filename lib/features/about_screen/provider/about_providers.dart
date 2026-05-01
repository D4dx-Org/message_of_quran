import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/about_model.dart';
import 'package:the_message_of_the_quran/core/services/database/about_db_helper.dart';

class AboutProvider extends ChangeNotifier {
  List<AboutModel>aboutList=[];
  bool isAboutLoading=false;
  Future<void>getAboutInfo()async{
    isAboutLoading=true;
    notifyListeners();
    try {
      aboutList = await AboutDbHelper.getAboutInfo();
    } catch (e) {
      debugPrint('AboutProvider: error loading about info – $e');
      aboutList = [];
    }
    isAboutLoading=false;
    notifyListeners();
  }

}