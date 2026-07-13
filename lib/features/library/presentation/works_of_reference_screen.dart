import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/authors_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_ready_notifier.dart';
import 'package:the_message_of_the_quran/core/services/database/works_of_reference_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class WorksOfReferenceScreen extends StatelessWidget {
  const WorksOfReferenceScreen({super.key});

  Map<String, Style> _htmlStyles({required Color bodyColor}) {
    return {
      'body': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        color: bodyColor,
        fontSize: FontSize(15),
        fontFamily: AppTextTheme.englishFontFamily,
      ),
      'p': Style(
        color: bodyColor,
        fontSize: FontSize(15),
        fontFamily: AppTextTheme.englishFontFamily,
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

  // On web the DB loads in the background after first paint; querying
  // before it's ready silently yields an empty list.
  Future<List<AuthorsModel>> _loadWorksOfReference(BuildContext context) async {
    final dbNotifier = context.read<DatabaseReadyNotifier>();
    if (dbNotifier.status != DbInitStatus.ready) {
      await dbNotifier.whenReady;
    }
    return WorksOfReferenceDbHelper.getWorksOfReference();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;
    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: 'Works of Reference',
        showLanguageButton: false,
      ),
      drawer: const CommonDrawer(),
      child: FutureBuilder<List<AuthorsModel>>(
        future: _loadWorksOfReference(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SelectableText(
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
              child: SelectableText(
                'No works of reference available',
                style: AppTextTheme.popinsDefault(
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
                            ..._htmlStyles(bodyColor: bodyColor),
                          },
                        )
                      : SelectableText(
                          'No Content available',
                          style: AppTextTheme.popinsDefault(
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