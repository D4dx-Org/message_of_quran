import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/translator_note_provider.dart';

class TranslatorNoteScreen extends StatefulWidget {
  const TranslatorNoteScreen({super.key});

  @override
  State<TranslatorNoteScreen> createState() => _TranslatorNoteScreenState();
}

class _TranslatorNoteScreenState extends State<TranslatorNoteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TranslatorNoteProvider>(context, listen: false)
          .getTranslatorNoteInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;

    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          'പരിഭാഷകന്റെ കുറിപ്പ്',
          style: AppTextTheme.localizedTitle(isMalayalam: true),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
        child: Consumer<TranslatorNoteProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.translatorNoteList.isEmpty) {
              return Center(
                child: Text(
                  'പരിഭാഷകന്റെ കുറിപ്പ് ലഭ്യമല്ല.',
                  style: AppTextTheme.localizedBody(
                    isMalayalam: true,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              );
            }
            final note = provider.translatorNoteList.first;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.content != null && note.content!.isNotEmpty)
                    ...note.content!.split('\n').where((p) => p.trim().isNotEmpty).expand((paragraph) => [
                      Text(
                        paragraph.trim(),
                        style: AppTextTheme.localizedBody(
                          isMalayalam: true,
                          fontSize: 14,
                          color: bodyColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ]),
                  if (note.author != null && note.author!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        '— ${note.author!}',
                        style: AppTextTheme.localizedBody(
                          isMalayalam: true,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: bodyColor,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
