import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/about_model.dart';
import 'package:the_message_of_the_quran/core/services/database/about_db_helper.dart';

class AboutProvider extends ChangeNotifier {
  List<AboutModel>aboutList=[];
  bool isAboutLoading=false;
  Future<void>getAboutInfo({bool malayalam = false})async{
    isAboutLoading=true;
    notifyListeners();
    if (!malayalam) {
      // Static English fallback until English DB is available
      aboutList = _englishAboutFallback;
    } else {
      try {
        aboutList = await AboutDbHelper.getAboutInfo(malayalam: malayalam);
      } catch (e) {
        debugPrint('AboutProvider: error loading about info – $e');
        aboutList = [];
      }
    }
    isAboutLoading=false;
    notifyListeners();
  }

  static final List<AboutModel> _englishAboutFallback = [
    AboutModel(
      title: 'The Message of the Quran',
      description:
          'The Message of the Quran is a mobile application dedicated to presenting '
          'the English translation and interpretation of the Holy Quran by Muhammad Asad. '
          'This app aims to provide readers with a clear, accessible, and scholarly '
          'understanding of the Quranic text.\n\n'
          'Muhammad Asad\'s translation is widely regarded as one of the most influential '
          'English renderings of the Quran, known for its clarity, depth of commentary, '
          'and sensitivity to the nuances of the Arabic language.\n\n'
          'Features include surah-wise reading, detailed footnotes, surah introductions, '
          'bookmarking, and audio recitation support.',
      createdBy: 'App Team',
      createdByRole: 'Developer',
      isVerified: 1,
    ),
  ];
}