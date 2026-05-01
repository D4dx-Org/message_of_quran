import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/responsive_content_wrapper.dart';
import 'package:the_message_of_the_quran/features/about_screen/provider/about_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AboutProvider>().getAboutInfo();
    });
  }

  Future<void> _launchBookPlusUrl() async {
    final uri = Uri.parse(ApiConstants.bookplusUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContentWrapper(
      child: Consumer<AboutProvider>(
        builder: (context, provider, _) {
          if (provider.isAboutLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.aboutList.isEmpty) {
            return const Center(child: Text('No information available'));
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...provider.aboutList.map((about) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (about.title != null && about.title!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: Center(
                            child: Text(
                              about.title!,
                              style: AppTextTheme.subTitleblack.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      if (about.description != null &&
                          about.description!.isNotEmpty)
                        Text(
                          about.description!,
                          textAlign: TextAlign.left,
                          style:
                              AppTextTheme.subTitleblack.copyWith(height: 1.7),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: _launchBookPlusUrl,
                      child: Text(
                        ApiConstants.bookplusUrl,
                        style: AppTextTheme.subTitleblack.copyWith(
                          color: Colors.blue,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                const  SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
