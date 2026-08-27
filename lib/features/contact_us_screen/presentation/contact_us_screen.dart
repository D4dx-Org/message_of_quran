import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/contact_us_screen/presentation/provider/contact_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isMalayalam =
          Provider.of<LanguageProvider>(context, listen: false).isMalayalam;
      await Provider.of<ContactProvider>(
        context,
        listen: false,
      ).getContactContent(isMalayalam: isMalayalam);
    });
  }

  Future<void> _launchPhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = digits.startsWith('91') ? '+$digits' : '+91$digits';
    final Uri phoneUri = Uri(scheme: 'tel', path: formatted);
    if (await canLaunchUrl(phoneUri)) {
      if (!mounted) return;
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('ContactUs: failed to launch email — $e');
    }
  }

  Future<void> _launchLink(LinkableElement link) async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam =
        Provider.of<LanguageProvider>(context).isMalayalam;

    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          isMalayalam ? 'ഞങ്ങളെ ബന്ധപ്പെടുക' : 'Contact Us',
          style: AppTextTheme.localizedTitle(isMalayalam: isMalayalam),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
          child: Consumer<ContactProvider>(
            builder: (context, contactProvider, child) {
              final content = contactProvider.contactContent;
              final description = content?.description;
              final address = content?.address;
              final email = content?.email;
              final mobile = content?.mobile;

              if (contactProvider.isContactLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description != null) ...[
                      Linkify(
                        text: description,
                        onOpen: _launchLink,
                        style: AppTextTheme.localizedBody(
                          isMalayalam: isMalayalam,
                          fontSize: 15,
                          height: 1.8,
                        ),
                        linkStyle: AppTextTheme.localizedBody(
                          isMalayalam: isMalayalam,
                          fontSize: 15,
                          height: 1.8,
                          color: Colors.blue,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (address != null || email != null || mobile != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.appIconTheme.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (mobile != null) ...[
                              GestureDetector(
                                onTap: () => _launchPhone(mobile),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      color: AppTheme.appIconTheme,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Phone',
                                            style: AppTextTheme.popinsDefault(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            mobile,
                                            style: AppTextTheme.popinsDefault(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Divider(height: 1),
                              ),
                            ],
                            if (email != null) ...[
                              GestureDetector(
                                onTap: () => _launchEmail(email),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      color: AppTheme.appIconTheme,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Email',
                                            style: AppTextTheme.popinsDefault(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            email,
                                            style: AppTextTheme.popinsDefault(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Divider(height: 1),
                              ),
                            ],
                            if (address != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: AppTheme.appIconTheme,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Address',
                                          style: AppTextTheme.popinsDefault(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address,
                                          style: AppTextTheme.localizedBody(
                                            isMalayalam: isMalayalam,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            height: 1.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
