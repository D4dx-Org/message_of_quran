import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/features/author_screen/author_screen.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/presentation/ayah_of_the_day_screen.dart';
import 'package:the_message_of_the_quran/features/contact_us_screen/presentation/contact_us_screen.dart';
import 'package:the_message_of_the_quran/features/help_screen/help_screen.dart';
import 'package:the_message_of_the_quran/features/library/presentation/appendix_screen.dart';
import 'package:the_message_of_the_quran/features/library/presentation/foreword_screen.dart';
import 'package:the_message_of_the_quran/features/library/presentation/works_of_reference_screen.dart';
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CommonDrawer extends StatelessWidget {
  const CommonDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeProvider>(context, listen: false);
    final isMl = context.watch<LanguageProvider>().isMalayalam;
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final drawerWidth = isTablet ? 360.0 : 304.0;

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Donation Card
            Padding(
              padding: EdgeInsets.fromLTRB(20 * scale, 16 * scale, 20 * scale, 0),
              child: Material(
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFA85A3A),
                        AppTheme.appThemePrimary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      try {
                        launchUrl(
                          Uri.parse('https://buymeacoffee.com/donateus'),
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        debugPrint('Drawer: failed to launch donate URL — $e');
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18 * scale,
                        vertical: 16 * scale,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10 * scale),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 24 * scale,
                            ),
                          ),
                          SizedBox(width: 14 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Support Us',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Contribute for Sadaqah Jariyah',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8 * scale),
            // Navigation items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _DrawerTile(
                      title: isMl ? 'ഹോം' : 'Home',
                      icon: Icons.home_outlined,
                      onTap: () {
                        controller.changeIndex(0);
                        Navigator.pop(context);
                        Navigator.popUntil(context, (r) => r.isFirst);
                      },
                    ),
                    _DrawerTile(
                      title: 'Ayah of the Day',
                      icon: Icons.auto_awesome_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AyahOfTheDayScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerTile(
                      title: isMl ? 'രചയിതാവ്' : 'About Author',
                      icon: Icons.person_outline,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthorScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerExpansionTile(
                      title: 'Library',
                      icon: Icons.local_library_outlined,
                      children: [
                        _DrawerSubTile(
                          title: 'Foreword',
                          icon: Icons.description_outlined,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForewordScreen(),
                              ),
                            );
                          },
                        ),
                        _DrawerSubTile(
                          title: 'Appendix',
                          icon: Icons.article_outlined,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppendixScreen(),
                              ),
                            );
                          },
                        ),
                        _DrawerSubTile(
                          title: 'Works of Reference',
                          icon: Icons.menu_book_outlined,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WorksOfReferenceScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    _DrawerTile(
                      title: 'Settings',
                      icon: Icons.settings_outlined,
                      onTap: () {
                        controller.changeIndex(3);
                        Navigator.pop(context);
                        Navigator.popUntil(context, (r) => r.isFirst);
                      },
                    ),
                    _DrawerTile(
                      title: 'Buy Printed Edition',
                      icon: Icons.book_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        try {
                          launchUrl(
                            Uri.parse(
                              'https://bookplus.co.in/books/vishudha-quran-vivarthanam/',
                            ),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          debugPrint('Drawer: failed to launch bookplus URL — $e');
                        }
                      },
                    ),
                    _DrawerTile(
                      title: 'Contact Us',
                      icon: Icons.chat_bubble_outline,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ContactUsScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerTile(
                      title: 'Help & Support',
                      icon: Icons.help_outline,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerTile(
                      title: 'Privacy',
                      icon: Icons.shield_outlined,
                      onTap: () {
                        try {
                          launchUrl(Uri.parse(ApiConstants.privacyPolicyUrl));
                        } catch (e) {
                          debugPrint('Drawer: failed to launch privacy URL — $e');
                        }
                      },
                    ),
                    _DrawerTile(
                      title: isMl ? 'അഭിപ്രായം അറിയിക്കുക' : 'Send Feedback',
                      icon: Icons.mail_outline,
                      onTap: () {
                        try {
                          launchUrl(
                            Uri(
                              scheme: 'mailto',
                              path: 'our.email@gmail.com',
                              queryParameters: {'subject': ''},
                            ),
                          );
                        } catch (e) {
                          debugPrint('Drawer: failed to launch email — $e');
                        }
                      },
                    ),
                    _DrawerTile(
                      title: 'Share App',
                      icon: Icons.share_outlined,
                      onTap: () async {
                        Navigator.pop(context);
                        await Future.delayed(const Duration(milliseconds: 300));
                        final link = Platform.isIOS
                            ? 'https://apps.apple.com/us/app/vishudha-quran/id6761527985'
                            : 'https://play.google.com/store/apps/details?id=com.d4dx.quran';
                        await Share.share(
                          'Check out The Message of The Quran \u2013 a beautiful Quran reader with Malayalam translation.\n$link',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 12 * scale),
              child: Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.title,
    required this.icon,
    this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.appIconTheme, size: 22 * scale),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 2 * scale),
      minLeadingWidth: 24 * scale,
      horizontalTitleGap: 14 * scale,
    );
  }
}

class _DrawerExpansionTile extends StatelessWidget {
  const _DrawerExpansionTile({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    return ExpansionTile(
      leading: Icon(icon, color: AppTheme.appIconTheme, size: 22 * scale),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      tilePadding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 0),
      childrenPadding: EdgeInsets.zero,
      iconColor: AppTheme.appIconTheme,
      collapsedIconColor: theme.colorScheme.outline,
      shape: const Border(),
      collapsedShape: const Border(),
      children: children,
    );
  }
}

class _DrawerSubTile extends StatelessWidget {
  const _DrawerSubTile({
    required this.title,
    required this.icon,
    this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.appIconTheme, size: 20 * scale),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: EdgeInsets.only(left: 56 * scale, right: 20 * scale),
      minLeadingWidth: 20 * scale,
      horizontalTitleGap: 12 * scale,
      dense: true,
    );
  }
}

