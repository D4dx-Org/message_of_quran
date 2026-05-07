import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/authors_model.dart';
import 'package:the_message_of_the_quran/core/services/database/author_db_helper.dart';

class AuthorProvider extends ChangeNotifier {

  List<AuthorsModel>authorsList=[];
  bool isAuthorsLoading=false;

  Future<void>getAuthorInfo({bool malayalam = false})async{
    isAuthorsLoading=true;
    notifyListeners();
    if (!malayalam) {
      // Static English fallback until English DB is available
      authorsList = _englishAuthorFallback;
    } else {
      authorsList = await AuthorDbHelper.getAuthors(malayalam: malayalam);
    }
    isAuthorsLoading=false;
    notifyListeners();
  }

  static final List<AuthorsModel> _englishAuthorFallback = [
    AuthorsModel(
      htmlContent: '''
<h2>Muhammad Asad (1900–1992)</h2>
<p>Muhammad Asad, born Leopold Weiss in Lemberg (now Lviv, Ukraine), was an Austro-Hungarian journalist, traveler, writer, linguist, political theorist, diplomat, and Islamic scholar.</p>
<p>After embracing Islam in 1926, he traveled extensively throughout the Muslim world. He became one of the most influential European Muslims of the 20th century.</p>
<h3>Major Works</h3>
<ul>
<li><strong>The Message of the Qur'an</strong> – A translation and commentary of the Holy Quran, widely acclaimed for its scholarly depth and linguistic clarity.</li>
<li><strong>The Road to Mecca</strong> – His autobiography describing his journey to Islam.</li>
<li><strong>The Principles of State and Government in Islam</strong> – A work on Islamic political philosophy.</li>
</ul>
<p>Asad spent over 17 years working on his translation and commentary of the Quran. His work is distinguished by its emphasis on the rationality of the Quranic message and its relevance to modern life.</p>
<p>He passed away on February 20, 1992, in Mijas, Spain.</p>
''',
      createdBy: 'App Team',
      createdByRole: 'Developer',
      isVerified: 1,
      id: 'english_fallback',
    ),
  ];
}