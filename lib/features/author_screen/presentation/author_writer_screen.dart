import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';

class AuthorWriterScreen extends StatelessWidget {
  const AuthorWriterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          'ഗ്രന്ഥകർത്താവ്',
          style: AppTextTheme.titleRegular,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: SingleChildScrollView(
          child: Text(
            'ഗ്രന്ഥകർത്താവിനെ കുറിച്ചുള്ള വിവരങ്ങൾ ഉടൻ ലഭ്യമാകും.',
            style: AppTextTheme.popinsDefault(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
