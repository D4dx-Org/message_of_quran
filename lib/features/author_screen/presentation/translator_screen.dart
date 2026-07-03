import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/core/widgets/bio_with_floating_image.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/translator_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  bool? _lastMalayalam;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TranslatorProvider>(context, listen: false)
          .getAboutAuthorInfo();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This screen only ever shows the Malayalam translator's bio. If the
    // user switches the app language away from Malayalam while it's still
    // on screen, hop over to its English sibling route instead of showing
    // stale Malayalam content.
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    if (_lastMalayalam != isMalayalam) {
      _lastMalayalam = isMalayalam;
      if (!isMalayalam) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pushReplacement('/translator-en');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;

    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: 'വിവർത്തകൻ',
      ),
      drawer: const CommonDrawer(),
      expandContentCard: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
        child: Consumer<TranslatorProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.aboutAuthorList.isEmpty) {
              return Center(
                child: SelectableText(
                  'വിവർത്തകനെ കുറിച്ചുള്ള വിവരങ്ങൾ ലഭ്യമല്ല.',
                  style: AppTextTheme.localizedBody(
                    isMalayalam: true,
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
                        child: SelectableText(
                          author.name!,
                          textAlign: TextAlign.center,
                          style: AppTextTheme.localizedTitle(
                            isMalayalam: true,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: bodyColor,
                          ),
                        ),
                      ),
                    ),
                  BioWithFloatingImage(
                    imagePath: 'assets/images/kc-saleem.png',
                    bioText: (author.bio != null && author.bio!.isNotEmpty)
                        ? author.bio!
                            .split('\n')
                            .where((p) => p.trim().isNotEmpty)
                            .map((p) => p.trim())
                            .join('\n\n')
                        : '',
                    textStyle: AppTextTheme.localizedBody(
                      isMalayalam: true,
                      fontSize: 14,
                      color: bodyColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                     if (author.mobile != null && author.mobile!.isNotEmpty)
                    SelectableText(
                        author.mobile!,
                      style: AppTextTheme.popinsDefault(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: bodyColor,
                      ),
                    ),
                  if (author.email != null && author.email!.isNotEmpty)
                    SelectableText(
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
