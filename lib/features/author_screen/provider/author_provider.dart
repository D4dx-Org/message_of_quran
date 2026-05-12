import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/authors_model.dart';

class AuthorProvider extends ChangeNotifier {

  List<AuthorsModel>authorsList=[];
  bool isAuthorsLoading=false;

  Future<void>getAuthorInfo({bool malayalam = false})async{
    isAuthorsLoading=true;
    notifyListeners();
    if (malayalam) {
      authorsList = _malayalamAuthorFallback;
    } else {
      authorsList = _englishAuthorFallback;
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

  static final List<AuthorsModel> _malayalamAuthorFallback = [
    AuthorsModel(
      htmlContent: '''
<h2>മുഹമ്മദ് അസദ് (1900–1992)</h2>
<p>ലെമ്ബെർഗില് (��ര്ത്തമാന ല്വീവ്, ഉക്രൈന്) ജനിച്ച ലിയോപോൾഡ് വൈസ് എന്ന പേരില് അറിയപ്പെട്ട മുഹമ്മദ് അസദ് ഒരു ഓസ്ട്രോ-ഹംഗേറിയൻ പത്രപ്രവർത്തകനും സഞ്ചാരിയും എഴുത്തുകാരനും ഭാഷാശാസ്ത്രജ്ഞനും ഇസ്ലാമിക പണ്ഡിതനും ആയിരുന്നു.</p>
<p>1926-ല് ഇസ്ലാം സ്വീകരിച്ച ശേഷം, മുസ്ലിം ലോകത്തിലുടനീളം സഞ്ചരിച്ചു. ഇരുപതാം നൂറ്റാണ്ടിലെ അത്യന്തം സ്വാധീനശക്തിയുള്ള യൂറോപ്യൻ മുസ്ലിംകളിൽ ഒരാളായി അദ്ദേഹം മാറി.</p>
<h3>പ്രധാന രചനകൾ</h3>
<ul>
<li><strong>The Message of the Quran</strong> – വിശുദ്ധ ഖുർആനിന്റെ പരിഭാഷയും വ്യാഖ്യാനവും. പാണ്ഡിത്യത്തിനും ഭാഷാ സ്പഷ്ടതയ്ക്കും പേരുകേട്ടത്.</li>
<li><strong>ദ റോഡ് ടു മെക്ക</strong> – ഇസ്ലാമിലേക്കുള്ള അദ്ദേഹത്തിന്റെ യാത്ര വിവരിക്കുന്ന ആത്മകഥ.</li>
<li><strong>ദ പ്രിൻസിപ്പിൾസ് ഓഫ് സ്റ്റേറ്റ് അൻഡ് ഗവൺമെന്റ് ഇൻ ഇസ്ലാം</strong> – ഇസ്ലാമിക രാഷ്ട്രീയ തത്വചിന്തയെക്കുറിച്ചുള്ള രചന.</li>
</ul>
<p>ഖുർആനിന്റെ പരിഭാഷയ്ക്കും വ്യാഖ്യാനത്തിനും അസദ് 17 വർഷത്തിലധികം പ്രയത്നിച്ചു. ഖുർആൻ സന്ദേശത്തിന്റെ യുക്തിബദ്ധതയ്ക്കും ആധുനിക ജീവിതത്തിലെ പ്രസക്തിക്കും നൽകുന്ന പ്രാധാന്യത്തിനും അദ്ദേഹത്തിന്റെ കൃതി പ്രശസ്തമാണ്.</p>
<p>1992 ഫെബ്രുവരി 20-ന് സ്പെയിനിലെ മിഹാസിൽ അദ്ദേഹം നിര്യാതനായി.</p>
''',
      createdBy: 'App Team',
      createdByRole: 'Developer',
      isVerified: 1,
      id: 'malayalam_fallback',
    ),
  ];
}