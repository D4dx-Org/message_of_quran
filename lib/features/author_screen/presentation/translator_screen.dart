import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/translator_provider.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TranslatorProvider>(context, listen: false)
          .getAboutAuthorInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;

    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          'വിവർത്തകൻ',
          style: AppTextTheme.titleRegular,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: Consumer<TranslatorProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.aboutAuthorList.isEmpty) {
              return Center(
                child: Text(
                  'വിവർത്തകനെ കുറിച്ചുള്ള വിവരങ്ങൾ ലഭ്യമല്ല.',
                  style: AppTextTheme.popinsDefault(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              );
            }
            final author = provider.aboutAuthorList.first;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (author.name != null && author.name!.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          author.name!,
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
                  if (author.bio != null && author.bio!.isNotEmpty)
                    ...author.bio!.split('\n').where((p) => p.trim().isNotEmpty).expand((paragraph) => [
                      Text(
                        paragraph.trim(),
                        style: AppTextTheme.popinsDefault(fontSize: 14, color: bodyColor),
                      ),
                      const SizedBox(height: 14),
                    ]),
                  const SizedBox(height: 16),
                     if (author.mobile != null && author.mobile!.isNotEmpty)
                    Text(
                      '${author.mobile!}',
                      style: AppTextTheme.popinsDefault(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: bodyColor,
                      ),
                    ),
                  if (author.email != null && author.email!.isNotEmpty)
                    Text(
                      'E-mail: ${author.email!}',
                      style: AppTextTheme.popinsDefault(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: bodyColor,
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
