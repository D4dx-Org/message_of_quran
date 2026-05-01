import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/contact_model.dart';
import 'package:the_message_of_the_quran/core/services/database/contact_db_helper.dart';

class ContactProvider extends ChangeNotifier{
  
  List<ContactModel>contactList=[];
  bool isContactLoading=false;
   Future<void>getContactInfo()async{
    isContactLoading=true;
    notifyListeners();
    try {
      contactList = await ContactDbHelper.getContactInfo();
    } catch (e) {
      debugPrint('ContactProvider: error loading contact info – $e');
      contactList = [];
    }
    isContactLoading=false;
    notifyListeners();
  }

}