import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/preface_model.dart';
import 'package:the_message_of_the_quran/core/services/database/preface_db_helper.dart';

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ആമുഖം'),
      ),
      body: FutureBuilder<PrefaceModel?>(
        future: PrefaceDbHelper.getGeneralPreface(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load introduction.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }
          final preface = snapshot.data;
          if (preface == null) {
            return const Center(
              child: Text(
                'No introduction available.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: SingleChildScrollView(
              child: Text(
                preface.prefaceText,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ),
          );
        },
      ),
    );
  }
}
