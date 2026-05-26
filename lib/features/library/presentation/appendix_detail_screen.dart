import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_message_of_the_quran/core/models/appendix_model.dart';
import 'package:the_message_of_the_quran/core/services/database/appendix_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

class AppendixDetailScreen extends StatelessWidget {
  const AppendixDetailScreen({
    super.key,
    required this.appendixNumber,
    required this.title,
  });

  final int appendixNumber;
  final String title;

  @override
  Widget build(BuildContext context) {
    const accentColor = AppTheme.appThemePrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;
    final isMalayalam = Provider.of<LanguageProvider>(context).isMalayalam;

    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          isMalayalam ? 'അനുബന്ധം' : 'Appendix',
          style: AppTextTheme.titleRegular,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () async {
              final appendix = await AppendixDbHelper.getAppendixByNumber(
                appendixNumber,
                malayalam: isMalayalam,
              );
              if (appendix != null) {
                await Share.share(
                  '${appendix.title}\n\n${appendix.body}',
                );
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      child: FutureBuilder<AppendixModel?>(
        future: AppendixDbHelper.getAppendixByNumber(
          appendixNumber,
          malayalam: isMalayalam,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text(
                'Failed to load appendix content.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }
          final appendix = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title banner - light background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          appendix.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Body text
                Text(
                  appendix.body,
                  style: TextStyle(fontSize: 15, height: 1.7, color: bodyColor),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
