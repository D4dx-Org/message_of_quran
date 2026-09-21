import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/constants/about_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/core/widgets/linked_body_text.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchD4dxUrl() async {
    final uri = Uri.parse('https://d4dx.co/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = Provider.of<LanguageProvider>(context).isMalayalam;
    final bodyColor = AppTextTheme.contentColor(context);
    final description = isMalayalam
        ? AboutInfo.descriptionMalayalam
        : AboutInfo.description;

    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: isMalayalam ? AboutInfo.titleMalayalam : AboutInfo.title,
      ),
      drawer: const CommonDrawer(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A clear line of air before the text starts, as on Contact Us.
              SizedBox(height: AppTextTheme.contentFontSize(context) * 1.7),
              LinkedBodyText(
                text: description,
                onUrlTap: _openUrl,
                anchors: {
                  AboutInfo.supportUsPhrase: () => context.push('/donate'),
                  AboutInfo.d4dxPhrase: _launchD4dxUrl,
                },
                style: AppTextTheme.localizedBody(
                  isMalayalam: isMalayalam,
                  fontSize: AppTextTheme.contentFontSize(context),
                  fontWeight: FontWeight.w500,
                  height: 1.7,
                  color: bodyColor,
                ),
                linkStyle: AppTextTheme.localizedBody(
                  isMalayalam: isMalayalam,
                  fontSize: AppTextTheme.contentFontSize(context),
                  fontWeight: FontWeight.w500,
                  height: 1.7,
                  color: Colors.blue,
                ).copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _launchD4dxUrl,
                  child: Text(
                    '- ${AboutInfo.signedBy}',
                    style: AppTextTheme.localizedLabel(
                      isMalayalam: isMalayalam,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
