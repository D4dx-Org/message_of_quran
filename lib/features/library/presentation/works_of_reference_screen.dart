import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:the_message_of_the_quran/core/models/authors_model.dart';
import 'package:the_message_of_the_quran/core/services/database/works_of_reference_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class WorksOfReferenceScreen extends StatelessWidget {
  const WorksOfReferenceScreen({super.key});

  Map<String, Style> _htmlStyles(
    BuildContext context, {
    required Color bodyColor,
  }) {
    return {
      'body': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        color: bodyColor,
        fontSize: FontSize(AppTextTheme.contentFontSize(context)),
        fontFamily: AppTextTheme.englishFontFamily,
      ),
      'p': Style(
        color: bodyColor,
        fontSize: FontSize(AppTextTheme.contentFontSize(context)),
        fontFamily: AppTextTheme.englishFontFamily,
      ),
      // The bold runs are Asad's own citation keys -- the short name each
      // work is referred to by in the notes -- so they stay bold. Without an
      // entry of their own they fell back to the package's defaults for face
      // and size, which is what made the list look unevenly set; pinning them
      // to the body's leaves weight as the only difference.
      'strong': Style(
        color: bodyColor,
        fontSize: FontSize(AppTextTheme.contentFontSize(context)),
        fontFamily: AppTextTheme.englishFontFamily,
        fontWeight: FontWeight.w600,
      ),
      'b': Style(
        color: bodyColor,
        fontSize: FontSize(AppTextTheme.contentFontSize(context)),
        fontFamily: AppTextTheme.englishFontFamily,
        fontWeight: FontWeight.w600,
      ),
      'h2': Style(
        display: Display.none,
        fontFamily: AppTextTheme.englishFontFamily,
      ),
      'a': Style(
        textDecoration: TextDecoration.none,
        color: bodyColor,
        fontFamily: AppTextTheme.englishFontFamily,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bodyColor = AppTextTheme.contentColor(context);
    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          'Works of Reference',
          style: AppTextTheme.titleRegular,
        ),
      ),
      child: FutureBuilder<List<AuthorsModel>>(
        future: WorksOfReferenceDbHelper.getWorksOfReference(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load works of reference.',
                style: AppTextTheme.englishDefault(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            );
          }

          final worksList = snapshot.data ?? [];
          if (worksList.isEmpty) {
            return Center(
              child: Text(
                'No works of reference available',
                style: AppTextTheme.englishDefault(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: ListView.builder(
              itemCount: worksList.length,
              itemBuilder: (context, index) {
                final html = worksList[index].htmlContent;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: html != null && html.isNotEmpty
                      ? Html(
                          data: html,
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
                          style: {
                            ..._htmlStyles(context, bodyColor: bodyColor),
                          },
                        )
                      : Text(
                          'No Content available',
                          style: AppTextTheme.englishDefault(
                            fontSize: 15,
                            color: bodyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}