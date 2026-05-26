import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/author_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthorScreen extends StatefulWidget {
  const AuthorScreen({super.key});

  @override
  State<AuthorScreen> createState() => _AuthorScreenState();
}

class _AuthorScreenState extends State<AuthorScreen> {
  bool? _lastMalayalam;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    if (_lastMalayalam != isMalayalam) {
      _lastMalayalam = isMalayalam;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<AuthorProvider>(context, listen: false)
              .getAuthorInfo(malayalam: isMalayalam);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;
    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          isMalayalam ? 'ഖുർആന്റെ സന്ദേശം' : 'About Author',
          style: AppTextTheme.titleRegular,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: Consumer<AuthorProvider>(
          builder: (context, authorProvider, child) {
            if (authorProvider.isAuthorsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (authorProvider.authorsList.isEmpty) {
              return Center(
                child: Text(
                  'No author information available',
                  style: AppTextTheme.popinsDefault(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: authorProvider.authorsList.length,
              itemBuilder: (context, index) {
                // final html = authorProvider.authorsList[index].htmlContent;
                // print(html);
                final rawHtml = authorProvider.authorsList[index].htmlContent;
                final hasContent = rawHtml != null && rawHtml.isNotEmpty;

                // For the first author (Muhammad Asad), extract title and show image
                if (index == 0 && hasContent) {
                  // Extract h2 title from HTML
                  final h2Regex = RegExp(r'<h2[^>]*>(.*?)</h2>', caseSensitive: false);
                  final h2Match = h2Regex.firstMatch(rawHtml);
                  final title = h2Match != null ? h2Match.group(1) ?? '' : '';
                  // Remove h2 from HTML so we render it separately
                  final bodyHtml = rawHtml.replaceFirst(h2Regex, '');

                  return Column(
                    children: [
                      if (title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextTheme.popinsDefault(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: bodyColor,
                            ),
                          ),
                        ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/asad_img.jpeg',
                              width: 300,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      if (bodyHtml.trim().isNotEmpty)
                        Html(
                          data: bodyHtml,
                          onLinkTap: (url, _, _) async {
                            if (url != null) {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          style: {
                            'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              color: bodyColor,
                              fontSize: FontSize(14),
                            ),
                            'p': Style(
                              color: bodyColor,
                              fontSize: FontSize(14),
                            ),
                            'h2': Style(
                              textAlign: TextAlign.center,
                              color: bodyColor,
                              fontSize: FontSize(18),
                              fontWeight: FontWeight.w600,
                            ),
                            'a': Style(
                              textDecoration: TextDecoration.none,
                              color: bodyColor,
                            ),
                          },
                        ),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: hasContent
                      ? Html(
                          data: rawHtml!,
                          onLinkTap: (url, _, _) async {
                            if (url != null) {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          style: {
                            'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              color: bodyColor,
                              fontSize: FontSize(14),
                            ),
                            'p': Style(
                              color: bodyColor,
                              fontSize: FontSize(14),
                            ),
                            'h2': Style(
                              textAlign: TextAlign.center,
                              color: bodyColor,
                              fontSize: FontSize(18),
                              fontWeight: FontWeight.w600,
                            ),
                            'a': Style(
                              textDecoration: TextDecoration.none,
                              color: bodyColor,
                            ),
                          },
                        )
                      : Text(
                          'No Content available',
                          style: AppTextTheme.subTitleblack,
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
