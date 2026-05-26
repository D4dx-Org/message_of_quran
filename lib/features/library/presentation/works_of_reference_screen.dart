import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:the_message_of_the_quran/core/models/authors_model.dart';
import 'package:the_message_of_the_quran/core/services/database/works_of_reference_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class WorksOfReferenceScreen extends StatelessWidget {
  const WorksOfReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                style: AppTextTheme.popinsDefault(
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
                style: AppTextTheme.popinsDefault(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
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
                            'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                            ),
                            'h2': Style(
                              display: Display.none,
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
            ),
          );
        },
      ),
    );
  }
}