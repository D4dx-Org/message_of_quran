import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/foreword_model.dart';
import 'package:the_message_of_the_quran/core/services/database/foreword_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';

class ForewordScreen extends StatelessWidget {
  const ForewordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          'Foreword',
          style: AppTextTheme.titleRegular,
        ),
      ),
      child: FutureBuilder<ForewordModel?>(
        future: ForewordDbHelper.getForeword(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load foreword.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }
          final foreword = snapshot.data;
          if (foreword == null) {
            return const Center(
              child: Text(
                'No foreword available.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: SingleChildScrollView(
              child: Text(
                foreword.body,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ),
          );
        },
      ),
    );
  }
}
