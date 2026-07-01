import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/features/about_screen/provider/about_providers.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({
    super.key,
    this.showStandaloneBackAppBar = false,
  });

  final bool showStandaloneBackAppBar;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool? _lastMalayalam;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    if (_lastMalayalam != isMalayalam) {
      _lastMalayalam = isMalayalam;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AboutProvider>().getAboutInfo(malayalam: isMalayalam);
        }
      });
    }
  }

  Future<void> _launchD4dxUrl() async {
    final uri = Uri.parse('https://d4dx.co/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: isMalayalam ? 'ഞങ്ങളെക്കുറിച്ച്' : 'About',
      ),
      expandContentCard: false,
      drawer: const CommonDrawer(),
      child: Consumer<AboutProvider>(
        builder: (context, provider, _) {
          if (provider.isAboutLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.aboutList.isEmpty) {
            return Center(
              child: SelectableText(
                'No Data',
                textAlign: TextAlign.center,
                style: AppTextTheme.popinsDefault(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...provider.aboutList.map((about) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (about.description != null &&
                          about.description!.isNotEmpty)
                        SelectableText(
                          about.description!,
                          textAlign: TextAlign.left,
                          style: AppTextTheme.localizedBody(
                            isMalayalam: isMalayalam,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.7,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (about.signedBy != null && about.signedBy!.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _launchD4dxUrl,
                            child: Text(
                              '- ${about.signedBy!}',
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
                      const SizedBox(height: 20),
                    ],
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
