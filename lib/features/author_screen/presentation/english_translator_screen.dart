import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/english_translator_provider.dart';

class EnglishTranslatorScreen extends StatefulWidget {
  const EnglishTranslatorScreen({super.key});
  @override
  State<EnglishTranslatorScreen> createState() =>
      _EnglishTranslatorScreenState();
}

class _EnglishTranslatorScreenState extends State<EnglishTranslatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EnglishTranslatorProvider>(context, listen: false)
          .getTranslatorInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;

    return BaseScreenLayout(
      appBar: AppBar(
        title: Text('Translator', style: AppTextTheme.titleRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: Consumer<EnglishTranslatorProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.translatorList.isEmpty) {
              return Center(
                child: Text(
                  'No translator information available.',
                  style: AppTextTheme.popinsDefault(
                      fontSize: 14, color: Colors.grey),
                ),
              );
            }
            final translator = provider.translatorList.first;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (translator.name != null && translator.name!.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          translator.name!,
                          textAlign: TextAlign.center,
                          style: AppTextTheme.popinsDefault(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: bodyColor,
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/kc-saleem.png',
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  if (translator.bio != null && translator.bio!.isNotEmpty)
                    ...translator.bio!
                        .split('\n')
                        .where((p) => p.trim().isNotEmpty)
                        .expand((paragraph) => [
                              Text(
                                paragraph.trim(),
                                style: AppTextTheme.popinsDefault(
                                    fontSize: 14, color: bodyColor),
                              ),
                              const SizedBox(height: 14),
                            ]),
                  const SizedBox(height: 16),
                  if (translator.address != null &&
                      translator.address!.isNotEmpty)
                    Text(
                      'Address: ${translator.address!}',
                      style: AppTextTheme.popinsDefault(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: bodyColor),
                    ),
                  if (translator.email != null && translator.email!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Email: ${translator.email!}',
                        style: AppTextTheme.popinsDefault(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: bodyColor),
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
