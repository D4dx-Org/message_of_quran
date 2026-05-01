import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/author_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthorScreen extends StatefulWidget {
  const AuthorScreen({super.key});

  @override
  State<AuthorScreen> createState() => _AuthorScreenState();
}

class _AuthorScreenState extends State<AuthorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AuthorProvider>(context, listen: false).getAuthorInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      appBar: AppBar(
        title: Text('About Author', style: AppTextTheme.titleRegular),
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: (authorProvider.authorsList[index].htmlContent != null &&
                   authorProvider.authorsList[index].htmlContent!.isNotEmpty)
                      ? Html(
                          data: authorProvider.authorsList[index].htmlContent!,
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
                            ),
                            'a': Style(
                              textDecoration: TextDecoration.none,
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
