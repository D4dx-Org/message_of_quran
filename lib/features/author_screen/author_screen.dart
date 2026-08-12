import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/core/widgets/bio_with_floating_image.dart';
import 'package:the_message_of_the_quran/core/services/database/database_ready_notifier.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/author_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';

class AuthorScreen extends StatefulWidget {
  const AuthorScreen({super.key});

  @override
  State<AuthorScreen> createState() => _AuthorScreenState();
}

class _AuthorScreenState extends State<AuthorScreen> {
  bool? _lastMalayalam;
  static final RegExp _h2Regex = RegExp(
    r'<h2[^>]*>.*?</h2>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _paragraphRegex = RegExp(
    r'<p\b[^>]*>.*?</p>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _htmlTagRegex = RegExp(r'<[^>]+>');
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  String _stripHtmlText(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(_htmlTagRegex, ' ')
        .replaceAll(_whitespaceRegex, ' ')
        .trim();
  }

  String _normalizeSignature(String value) {
    return _stripHtmlText(value)
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(':', '')
        .replaceAll(';', '')
        .replaceAll('-', ' ')
        .replaceAll('—', ' ')
        .replaceAll(_whitespaceRegex, ' ')
        .trim()
        .toLowerCase();
  }

  Map<String, String?> _extractFirstAuthorContent(
    String rawHtml,
    String? createdBy,
  ) {
    final cleanedHtml = rawHtml.replaceFirst(_h2Regex, '').trim();
    final signature = createdBy?.trim();

    if (signature == null || signature.isEmpty) {
      return {'bodyHtml': cleanedHtml, 'signature': null};
    }

    final paragraphMatches = _paragraphRegex.allMatches(cleanedHtml).toList();
    if (paragraphMatches.isEmpty) {
      return {'bodyHtml': cleanedHtml, 'signature': null};
    }

    final lastParagraphMatch = paragraphMatches.last;
    final lastParagraphHtml = lastParagraphMatch.group(0)!;
    final lastParagraphText = _stripHtmlText(lastParagraphHtml);

    if (_normalizeSignature(lastParagraphText) !=
        _normalizeSignature(signature)) {
      return {'bodyHtml': cleanedHtml, 'signature': null};
    }

    return {
      'bodyHtml': cleanedHtml
          .substring(0, lastParagraphMatch.start)
          .trimRight(),
      'signature': lastParagraphText,
    };
  }

  Map<String, Style> _buildHtmlStyles({
    required bool isMalayalam,
    required Color bodyColor,
  }) {
    final fontFamily = AppTextTheme.localizedFontFamily(
      isMalayalam: isMalayalam,
    );
    return {
      'body': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        color: bodyColor,
        fontSize: FontSize(15),
        fontFamily: fontFamily,
      ),
      'p': Style(
        color: bodyColor,
        fontSize: FontSize(15),
        fontFamily: fontFamily,
      ),
      'h2': Style(
        textAlign: TextAlign.center,
        color: bodyColor,
        fontSize: FontSize(18),
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      ),
      'a': Style(
        textDecoration: TextDecoration.none,
        color: bodyColor,
        fontFamily: fontFamily,
      ),
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    if (_lastMalayalam != isMalayalam) {
      _lastMalayalam = isMalayalam;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await context.read<DatabaseReadyNotifier>().whenReady;
        if (!mounted) return;
        Provider.of<AuthorProvider>(
          context,
          listen: false,
        ).getAuthorInfo(malayalam: isMalayalam);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;
    final dbLoading =
        context.watch<DatabaseReadyNotifier>().status == DbInitStatus.loading;
    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: isMalayalam ? 'മുഹമ്മദ് അസദ്' : 'Muhammad Asad',
      ),
      drawer: const CommonDrawer(),
      contentBottomInset: BaseScreenLayout.defaultContentTopInset,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
        child: Consumer<AuthorProvider>(
          builder: (context, authorProvider, child) {
            if (authorProvider.isAuthorsLoading || dbLoading) {
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
                final author = authorProvider.authorsList[index];
                final rawHtml = author.htmlContent;
                final hasContent = rawHtml != null && rawHtml.isNotEmpty;

                // For the first author (Muhammad Asad), remove the inline title and show the image first.
                if (index == 0 && hasContent) {
                  final firstAuthorContent = _extractFirstAuthorContent(
                    rawHtml,
                    author.createdBy,
                  );
                  final bodyHtml = firstAuthorContent['bodyHtml'] ?? '';
                  final signature = firstAuthorContent['signature'];
                  final plainParagraphs = _paragraphRegex
                      .allMatches(bodyHtml)
                      .map((m) => _stripHtmlText(m.group(0)!))
                      .where((p) => p.isNotEmpty)
                      .toList();
                  final bioText = plainParagraphs.isNotEmpty
                      ? plainParagraphs.join('\n\n')
                      : _stripHtmlText(bodyHtml);

                  return Column(
                    children: [
                      if (bioText.isNotEmpty)
                        BioWithFloatingImage(
                          imagePath: '${ApiConstants.imageCdnBaseUrl}/asad_img.jpeg',
                          thumbnailPath: 'assets/images/asad_img_thumb.jpeg',
                          bioText: bioText,
                          textStyle: AppTextTheme.localizedBody(
                            isMalayalam: isMalayalam,
                            fontSize: 15,
                            color: bodyColor,
                          ),
                        ),
                      if (signature != null) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            signature,
                            style: AppTextTheme.localizedBody(
                              isMalayalam: isMalayalam,
                              fontSize: isMalayalam ? 16 : 15,
                              fontWeight: FontWeight.w700,
                              color: bodyColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: hasContent
                      ? Html(
                          data: rawHtml,
                          onLinkTap: (url, _, _) async {
                            if (url != null) {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }
                          },
                          style: _buildHtmlStyles(
                            isMalayalam: isMalayalam,
                            bodyColor: bodyColor,
                          ),
                        )
                      : Text(
                          'No Content available',
                          style: AppTextTheme.popinsDefault(
                            fontSize: 15,
                            color: bodyColor,
                            fontWeight: FontWeight.w500,
                          ),
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
