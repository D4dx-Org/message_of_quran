import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/preface_model.dart';
import 'package:the_message_of_the_quran/core/services/database/preface_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          'ആമുഖം',
          style: AppTextTheme.localizedTitle(isMalayalam: true),
        ),
      ),
      child: FutureBuilder<PrefaceModel?>(
        future: PrefaceDbHelper.getGeneralPreface(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load introduction.',
                style: AppTextTheme.localizedBody(
                  isMalayalam: true,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            );
          }
          final preface = snapshot.data;
          if (preface == null) {
            return Center(
              child: Text(
                'No introduction available.',
                style: AppTextTheme.localizedBody(
                  isMalayalam: true,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: SingleChildScrollView(
              child: Text(
                preface.prefaceText,
                style: AppTextTheme.localizedBody(
                  isMalayalam: true,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
