import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/services/database/about_db_helper.dart';
import 'package:the_message_of_the_quran/core/models/about_model.dart';

class AboutProvider extends ChangeNotifier {
  List<AboutModel>aboutList=[];
  bool isAboutLoading=false;
  Future<void>getAboutInfo({bool malayalam = false})async{
    isAboutLoading=true;
    notifyListeners();
    aboutList = await AboutDbHelper.getAboutInfo(malayalam: malayalam);
    isAboutLoading=false;
    notifyListeners();
  }
}