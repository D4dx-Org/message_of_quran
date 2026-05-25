import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/contact_content_model.dart';
import 'package:the_message_of_the_quran/core/models/contact_model.dart';
import 'package:the_message_of_the_quran/core/services/database/contact_db_helper.dart';

class ContactProvider extends ChangeNotifier {
  List<ContactModel> contactList = [];
  ContactContentModel? contactContent;
  bool isContactLoading = false;

  Future<void> getContactInfo() async {
    isContactLoading = true;
    notifyListeners();
    try {
      contactList = await ContactDbHelper.getContactInfo();
    } catch (e) {
      debugPrint('ContactProvider: error loading contact info – $e');
      contactList = [];
    }
    isContactLoading = false;
    notifyListeners();
  }

  Future<void> getContactContent({bool isMalayalam = true}) async {
    isContactLoading = true;
    notifyListeners();
    try {
      if (isMalayalam) {
        contactContent = await ContactDbHelper.getContactContent();
      } else {
        contactContent = await ContactDbHelper.getEnglishContactContent();
      }
    } catch (e) {
      debugPrint('ContactProvider: error loading contact content – $e');
      contactContent = null;
    }
    isContactLoading = false;
    notifyListeners();
  }
}