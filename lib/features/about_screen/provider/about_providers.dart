import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/about_model.dart';

class AboutProvider extends ChangeNotifier {
  List<AboutModel>aboutList=[];
  bool isAboutLoading=false;
  Future<void>getAboutInfo({bool malayalam = false})async{
    isAboutLoading=true;
    notifyListeners();
    if (malayalam) {
      aboutList = _malayalamAboutFallback;
    } else {
      aboutList = _englishAboutFallback;
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

  static final List<AboutModel> _malayalamAboutFallback = [
    AboutModel(
      title: 'The Message of the Quran',
      description:
          'The Message of the Quran എന്നത് മുഹമ്മദ് അസദിന്റെ വിശുദ്ധ ഖുർആൻ '
          'പരിഭാഷയും വ്യാഖ്യാനവും പ്രസിദ്ധീകരിക്കുന്നതിനായി '
          'സമർപ്പിച്ചിട്ടുള്ള ഒരു മൊബൈൽ ആപ്ലിക്കേഷനാണ്.\n\n'
          'ഖുർആനിന്റെ അർത്ഥത്തിന്റെ യുക്തിബദ്ധതയ്ക്കും ആധുനിക ജീവിതത്തിലെ '
          'പ്രസക്തിക്കും പ്രാധാന്യം നൽകുന്ന അസദിന്റെ പരിഭാഷ '
          'ഇംഗ്ലീഷിലെ അത്യന്തം സ്വാധീനശക്തിയുള്ള ഒന്നായി കണക്കാക്കപ്പെടുന്നു.\n\n'
          'സൂറത്ത് അടിസ്ഥാനത്തിലുള്ള വായന, വിശദമായ അടിക്കുറിപ്പുകൾ, സൂറത്ത് '
          'ആമുഖം, ബുക്ക്മാർക്കിംഗ്, ഓഡിയോ പാരായണം എന്നിവ ഇതിന്റെ '
          'സവിശേഷതകളിൽ ഉൾപ്പെടുന്നു.',
      createdBy: 'App Team',
      createdByRole: 'Developer',
      isVerified: 1,
    ),
  ];
}