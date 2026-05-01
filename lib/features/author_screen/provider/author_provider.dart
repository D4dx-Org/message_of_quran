import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/authors_model.dart';
import 'package:the_message_of_the_quran/core/services/database/author_db_helper.dart';

class AuthorProvider extends ChangeNotifier {

  List<AuthorsModel>authorsList=[];
  bool isAuthorsLoading=false;

  Future<void>getAuthorInfo()async{
    isAuthorsLoading=true;
    notifyListeners();
    authorsList = await AuthorDbHelper.getAuthors();
    isAuthorsLoading=false;
    notifyListeners();
  }
}