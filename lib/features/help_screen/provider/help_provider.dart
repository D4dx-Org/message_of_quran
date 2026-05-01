import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/faq_category_model.dart';
import 'package:the_message_of_the_quran/core/models/help_model.dart';
import 'package:the_message_of_the_quran/core/services/database/help_db_helper.dart';
import 'package:the_message_of_the_quran/features/help_screen/data/static_faq_data.dart';

class HelpProvider extends ChangeNotifier {
  List<FaqCategory> faqCategories = [];
  List<HelpModel> helpList = [];
  bool isHelpLoading = false;

  Future<void> getHelpInfo() async {
    isHelpLoading = true;
    notifyListeners();
    try {
      helpList = await HelpDbHelper.getHelpInfo();
    } catch (e) {
      debugPrint('HelpProvider: error loading help info – $e');
      helpList = [];
    }
    _buildFaqCategories();
    isHelpLoading = false;
    notifyListeners();
  }

  void _buildFaqCategories() {
    faqCategories = List.from(StaticFaqData.faqCategories);
    if (helpList.isNotEmpty) {
      faqCategories.add(
        FaqCategory(categoryName: 'General', items: helpList),
      );
    }
  }
}