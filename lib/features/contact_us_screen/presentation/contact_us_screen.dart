import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/contact_us_screen/presentation/provider/contact_provider.dart';
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
      await Provider.of<ContactProvider>(
        context,
        listen: false,
      ).getContactInfo();
    });
  }
  Future<void> _launchPhone() async {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final phone = contactProvider.contactList.isNotEmpty
        ? contactProvider.contactList[0].mobile.toString()
        : '+916598321478';
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      if (!mounted) return;
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchWhatsapp() async {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final whatsapp = contactProvider.contactList.isNotEmpty
        ? contactProvider.contactList[0].whatsapp.toString().replaceAll(RegExp(r'[^0-9]'), '')
        : '919946666139';
    final Uri whatsappUri = Uri.parse('https://wa.me/$whatsapp');
    if (await canLaunchUrl(whatsappUri)) {
      if (!mounted) return;
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final email = contactProvider.contactList.isNotEmpty
        ? contactProvider.contactList[0].email.toString()
        : 'mail@d4dx.co';
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('ContactUs: failed to launch email — $e');
      // No email app available
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      appBar: AppBar(),
      child: Container(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Get in Touch',
                    style: AppTextTheme.popinsDefault(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'We\'d love to hear from you',
                    style: AppTextTheme.popinsDefault(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    // color: Colors.white,
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
                      GestureDetector(
                        onTap: _launchPhone,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone',
                                  style: AppTextTheme.popinsDefault(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Consumer<ContactProvider>(
                                  builder: (context, contactProvider, child) {
                                    return Text(
                                      contactProvider.contactList.isEmpty
                                          ? "+91 6598321478"
                                          : contactProvider
                                                .contactList[0]
                                                .mobile
                                                .toString(),
                                      style: AppTextTheme.popinsDefault(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
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
                       GestureDetector(
                        onTap: _launchWhatsapp,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat,
                              color: AppTheme.appIconTheme,
                              size: 24,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Whatsapp',
                                  style: AppTextTheme.popinsDefault(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Consumer<ContactProvider>(
                                  builder: (context, contactProvider, child) {
                                    return Text(
                                      contactProvider.contactList.isEmpty
                                          ? "+91 99466 66139"
                                          : contactProvider
                                                .contactList[0]
                                                .whatsapp
                                                .toString(),
                                      style: AppTextTheme.popinsDefault(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
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
                      GestureDetector(
                        onTap: _launchEmail,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: AppTextTheme.popinsDefault(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Consumer<ContactProvider>(
                                  builder: (context, contactProvider, child) {
                                    return Text(
                                      contactProvider.contactList.isEmpty
                                          ? "mail@d4dx.co"
                                          : contactProvider.contactList[0].email
                                                .toString(),
                                      style: AppTextTheme.popinsDefault(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Address',
                                  style: AppTextTheme.popinsDefault(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Consumer<ContactProvider>(
                                  builder: (context, contactProvider, child) {
                                    return Text(
                                      contactProvider.contactList.isEmpty
                                          ? "D4DX Innovations LLP\nMavoor Road, Calicut, Kerala, Pin 673004"
                                          : contactProvider
                                                .contactList[0]
                                                .address
                                                .toString(),
                                      style: AppTextTheme.popinsDefault(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
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
          ),
        ),
      ),
    );
  }
}
