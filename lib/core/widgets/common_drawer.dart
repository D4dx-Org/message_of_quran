import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/constants/useful_links.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/d4dx_branding_footer.dart';
import 'package:the_message_of_the_quran/features/author_screen/author_screen.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/presentation/ayah_of_the_day_screen.dart';
import 'package:the_message_of_the_quran/features/contact_us_screen/presentation/contact_us_screen.dart';
import 'package:the_message_of_the_quran/features/help_screen/help_screen.dart';
import 'package:the_message_of_the_quran/features/library/presentation/appendix_screen.dart';
import 'package:the_message_of_the_quran/features/library/presentation/foreword_screen.dart';
import 'package:the_message_of_the_quran/features/library/presentation/works_of_reference_screen.dart';
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/common_email/presentation/feedback_screen.dart';
import 'package:the_message_of_the_quran/features/common_email/presentation/feature_request_screen.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/presentation/prostration_verses_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CommonDrawer extends StatelessWidget {
  const CommonDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeProvider>(context, listen: false);
    final isMalayalam = Provider.of<LanguageProvider>(context).isMalayalam;
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
              _DrawerBrandHeader(
                onSupportTap: () async {
                  try {
                    await launchUrl(
                      Uri.parse('https://buymeacoffee.com/donateus'),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (e) {
                    debugPrint('Drawer: failed to launch donate URL - $e');
                  }
                },
              ),
              SizedBox(height: 2 * scale),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: 4 * scale, bottom: 8 * scale),
                  child: Column(
                    children: [
                      _DrawerTile(
                        title: 'Home',
                        icon: Icons.home_outlined,
                        onTap: () {
                          controller.changeIndex(0);
                          Navigator.pop(context);
                          Navigator.popUntil(context, (route) => route.isFirst);
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
                        title: 'About Author',
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
                      _DrawerTile(
                        title: isMalayalam
                            ? 'സുജൂദിന്റെ ആയത്തുകൾ'
                            : 'Prostration Verses',
                        icon: Icons.mosque_outlined,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProstrationVersesScreen(),
                            ),
                          );
                        },
                      ),
                      _DrawerExpansionTile(
                        title: 'Library',
                        icon: Icons.auto_stories_outlined,
                        children: [
                          _DrawerSubTile(
                            title: isMalayalam ? 'മുഖവുര' : 'Foreword',
                            icon: Icons.history_edu_outlined,
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
                            icon: Icons.note_alt_outlined,
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
                            icon: Icons.library_books_outlined,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const WorksOfReferenceScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      _DrawerExpansionTile(
                        title: 'Useful Links',
                        icon: Icons.link_outlined,
                        children: [
                          for (final section in usefulLinksSections) ...[
                            _DrawerSectionHeader(title: section.title),
                            for (final link in section.links)
                              _DrawerLinkTile(
                                title: link.title,
                                url: link.url,
                              ),
                          ],
                        ],
                      ),
                      _DrawerTile(
                        title: 'Settings',
                        icon: Icons.settings_outlined,
                        onTap: () {
                          controller.changeIndex(3);
                          Navigator.pop(context);
                          Navigator.popUntil(context, (route) => route.isFirst);
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
                            debugPrint(
                              'Drawer: failed to launch privacy URL — $e',
                            );
                          }
                        },
                      ),
                      _DrawerTile(
                        title: 'Feedback',
                        icon: Icons.mail_outline,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FeedbackScreen(),
                            ),
                          );
                        },
                      ),
                      _DrawerTile(
                        title: 'Feature Request',
                        icon: Icons.lightbulb_outline,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FeatureRequestScreen(),
                            ),
                          );
                        },
                      ),
                      _DrawerTile(
                        title: 'Share App',
                        icon: Icons.share_outlined,
                        onTap: () async {
                          Navigator.pop(context);
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );
                          final link = Platform.isIOS
                              ? 'https://apps.apple.com/us/app/vishudha-quran/id6761527985'
                              : 'https://play.google.com/store/apps/details?id=com.d4dx.quran';
                          await Share.share(
                            'Check out The Message of The Quran – a beautiful Quran reader with Malayalam translation.\n$link',
                          );
                        },
                      ),
                      SizedBox(height: 6 * scale),
                      const _DrawerFooter(),
                    ],
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

class _DrawerBrandHeader extends StatelessWidget {
  const _DrawerBrandHeader({required this.onSupportTap});

  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final headerColor =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.secondary;
    final headerAccent = appBarTitleMatchedAccentColor(context);
    final borderRadius = BorderRadius.circular(28 * scale);
    final shadowColor = isDarkMode(context: context)
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.08);
    return Padding(
      padding: EdgeInsets.fromLTRB(14 * scale, 0, 14 * scale, 6 * scale),
      child: Container(
        key: const ValueKey('drawer-brand-header'),
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 24 * scale,
              offset: Offset(0, 10 * scale),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              Positioned(
                top: -20 * scale,
                right: -24 * scale,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isDarkMode(context: context) ? 0.16 : 0.12,
                    child: Image.asset(
                      'assets/images/home_side_image.png',
                      width: 118 * scale,
                      fit: BoxFit.contain,
                      color: headerAccent,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  18 * scale,
                  16 * scale,
                  18 * scale,
                  18 * scale,
                ),
                child: Column(
                  children: [
                    Center(
                      key: const ValueKey('drawer-brand-logo-box'),
                      child: Image.asset(
                        'assets/images/Group-logo.png',
                        height: 44 * scale,
                        fit: BoxFit.contain,
                        semanticLabel: 'The Message of the Quran logo',
                      ),
                    ),
                    SizedBox(height: 14 * scale),
                    SizedBox(
                      key: const ValueKey('drawer-support-button-box'),
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onSupportTap,
                        icon: Icon(
                          Icons.volunteer_activism_outlined,
                          size: 18 * scale,
                        ),
                        label: Text(
                          'Support Us',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: headerAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: headerAccent,
                          backgroundColor: Colors.white.withValues(
                            alpha: isDarkMode(context: context) ? 0.04 : 0.02,
                          ),
                          side: BorderSide(
                            color: headerAccent.withValues(alpha: 0.92),
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20 * scale,
                            vertical: 12 * scale,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return const D4dxBrandingFooter(
      key: ValueKey('drawer-footer'),
      versionLabel: 'Version 1.0.0',
      showTopBorder: true,
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({required this.title, required this.icon, this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final accentColor = appBarAccentColor(context);

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: accentColor, size: 22 * scale),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 20 * scale,
        vertical: 2 * scale,
      ),
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
    final accentColor = appBarAccentColor(context);

    return ExpansionTile(
      leading: Icon(icon, color: accentColor, size: 22 * scale),
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
      iconColor: accentColor,
      collapsedIconColor: accentColor,
      shape: const Border(),
      collapsedShape: const Border(),
      children: children,
    );
  }
}

class _DrawerSubTile extends StatelessWidget {
  const _DrawerSubTile({required this.title, required this.icon, this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final accentColor = appBarAccentColor(context);

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: accentColor, size: 20 * scale),
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

class _DrawerSectionHeader extends StatelessWidget {
  const _DrawerSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final accentColor = appBarAccentColor(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        56 * scale,
        10 * scale,
        20 * scale,
        4 * scale,
      ),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      ),
    );
  }
}

class _DrawerLinkTile extends StatelessWidget {
  const _DrawerLinkTile({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);

    return ListTile(
      onTap: () async {
        Navigator.pop(context);
        try {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('Drawer: failed to launch link — $e');
        }
      },
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.open_in_new,
        size: 16 * scale,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      ),
      contentPadding: EdgeInsets.only(left: 68 * scale, right: 16 * scale),
      horizontalTitleGap: 0,
      dense: true,
    );
  }
}
