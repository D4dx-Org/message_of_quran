import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/constants/useful_links.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/d4dx_branding_footer.dart';
import 'package:the_message_of_the_quran/core/widgets/shimmer_asset_image.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';
import 'package:the_message_of_the_quran/core/utils/platform_helper.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CommonDrawer extends StatelessWidget {
  const CommonDrawer({super.key});

  Rect? _sharePositionOriginFor(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize ||
        renderObject.size.isEmpty) {
      return null;
    }

    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  @override
  Widget build(BuildContext context) {
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
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DrawerBrandHeader(
                onSupportTap: () async {
                  try {
                    await launchUrl(
                      Uri.parse(' '),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (e) {
                    debugPrint('Drawer: failed to launch donate URL - $e');
                  }
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: 1 * scale, bottom: 8 * scale),
                  child: Column(
                    children: [
                      _DrawerTile(
                        title: 'Home',
                        icon: Icons.home_outlined,
                        assetPath: 'assets/icons/home-img.png',
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/');
                        },
                      ),
                      if (isMalayalam)
                        _DrawerExpansionTile(
                          title: 'ഖുർആന്റെ സന്ദേശം',
                          icon: Icons.menu_book_outlined,
                          isMalayalam: true,
                          children: [
                            _DrawerSubTile(
                              title: 'മുഹമ്മദ് അസദ്',
                              icon: Icons.edit_outlined,
                              isMalayalam: true,
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/author');
                              },
                            ),
                            _DrawerSubTile(
                              title: 'വിവർത്തകൻ',
                              icon: Icons.translate_outlined,
                              isMalayalam: true,
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/translator');
                              },
                            ),
                          ],
                        )
                      else
                        _DrawerExpansionTile(
                          title: 'Message of the Qur\'an',
                          icon: Icons.menu_book_outlined,
                          children: [
                            _DrawerSubTile(
                              title: 'Muhammad Asad',
                              icon: Icons.edit_outlined,
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/author');
                              },
                            ),
                            _DrawerSubTile(
                              title: 'Translator',
                              icon: Icons.translate_outlined,
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/translator-en');
                              },
                            ),
                          ],
                        ),
                      _DrawerExpansionTile(
                        title: isMalayalam ? 'ലൈബ്രറി' : 'Library',
                        icon: Icons.auto_stories_outlined,
                        isMalayalam: isMalayalam,
                        children: [
                          _DrawerSubTile(
                            title: isMalayalam ? 'മുഖവുര' : 'Foreword',
                            icon: Icons.history_edu_outlined,
                            isMalayalam: isMalayalam,
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/foreword');
                            },
                          ),
                          _DrawerSubTile(
                            title: isMalayalam ? 'അനുബന്ധം' : 'Appendix',
                            icon: Icons.note_alt_outlined,
                            isMalayalam: isMalayalam,
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/appendix');
                            },
                          ),
                          if (!isMalayalam)
                            _DrawerSubTile(
                              title: 'Works of Reference',
                              icon: Icons.library_books_outlined,
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/works-of-reference');
                              },
                            ),
                        ],
                      ),
                      _DrawerTile(
                        title: isMalayalam
                            ? 'സുജൂദിന്റെ ആയത്തുകൾ'
                            : 'Prostration Verses',
                        icon: Icons.mosque_outlined,
                        isMalayalam: isMalayalam,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/prostration-verses');
                        },
                      ),
                      for (final section in usefulLinksSections)
                        _DrawerExpansionTile(
                          title: section.title,
                              icon: section.icon,
                          children: [
                            for (final link in section.links)
                              _DrawerLinkTile(
                                title: link.title,
                                url: link.url,
                              ),
                          ],
                        ),
                    const  _DrawerExpansionTile(
                        title: 'Kids',
                        icon: Iconsax.magic_star,
                        children: [
                          _DrawerLinkTile(
                            title: "Kids Qur'an",
                            url: 'https://www.alim.org/kids-quran/',
                          ),
                        ],
                      ),
                      _DrawerTile(
                        title: 'Feedback',
                        icon: Icons.mail_outline,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/feedback');
                        },
                      ),
                      _DrawerTile(
                        title: 'Contact Us',
                        icon: Icons.chat_bubble_outline,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/contact-us');
                        },
                      ),
                      if (!PlatformHelper.isWeb)
                      _DrawerTile(
                        title: 'Share App',
                        icon: Icons.share_outlined,
                        onTapWithContext: (tileContext) async {
                          final sharePositionOrigin =
                              _sharePositionOriginFor(tileContext);
                          Navigator.pop(context);
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );
                          final buffer = StringBuffer()
                            ..writeln(
                              'Check out Quran Asad Malayalam – a beautiful Quran reader with Malayalam translation.',
                            )
                            ..writeln(
                              'Android : ${AppConstants.androidStoreUrl}',
                            );
                          if (AppConstants.iosStoreUrl.isNotEmpty) {
                            buffer.writeln('iOS : ${AppConstants.iosStoreUrl}');
                          }
                          await Share.share(
                            buffer.toString().trimRight(),
                            sharePositionOrigin: sharePositionOrigin,
                          );
                        },
                      ),
                      _DrawerTile(
                        title: 'Settings',
                        icon: Icons.settings_outlined,
                        assetPath: 'assets/icons/settings-img.png',
                        onTap: () {
                          Navigator.pop(context);
                          showSettingsDialog(context);
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

class _HalfMoonClipper extends CustomClipper<Path> {
  const _HalfMoonClipper({this.curveDepth = 30.0});

  final double curveDepth;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - curveDepth)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + curveDepth,
        size.width,
        size.height - curveDepth,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _HalfMoonClipper oldClipper) =>
      oldClipper.curveDepth != curveDepth;
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
    final curveDepth = 28.0 * scale;
    return Container(
      key: const ValueKey('drawer-brand-header'),
      margin: EdgeInsets.only(bottom: 8 * scale),
      child: ClipPath(
        clipper: _HalfMoonClipper(curveDepth: curveDepth),
        child: Container(
          color: headerColor,
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
                  24 * scale,
                  16 * scale + MediaQuery.paddingOf(context).top,
                  24 * scale,
                  28 * scale,
                ),
                child: Column(
                  children: [
                    Center(
                      key: const ValueKey('drawer-brand-logo-box'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/symbol-logo.png',
                            height: 52 * scale,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            semanticLabel: 'The Message of the Quran logo symbol',
                          ),
                          SizedBox(width: 4 * scale),
                          Image.asset(
                            'assets/images/symbol-logo-text.png',
                            height: 46 * scale,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            semanticLabel: 'The Message of the Quran logo text',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18 * scale),
                    SizedBox(
                      key: const ValueKey('drawer-support-button-box'),
                      // width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onSupportTap,
                        label: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            'Support Us',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: headerAccent,
                              fontWeight: FontWeight.w700,
                            ),
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
      versionLabel: ' ${AppConstants.appVersion}',
      showTopBorder: true,
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.title,
    required this.icon,
    this.onTap,
    this.onTapWithContext,
    this.assetPath,
    this.isMalayalam = false,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Future<void> Function(BuildContext context)? onTapWithContext;
  final String? assetPath;
  final bool isMalayalam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final accentColor = appBarAccentColor(context);

    final leadingWidget = assetPath != null
        ? ShimmerAssetImage(
            assetPath!,
            width: 22 * scale,
            height: 22 * scale,
            color: accentColor,
          )
        : Icon(icon, color: accentColor, size: 22 * scale);

    return Builder(
      builder: (tileContext) => ListTile(
        onTap: () async {
          if (onTapWithContext != null) {
            await onTapWithContext!(tileContext);
            return;
          }
          onTap?.call();
        },
        leading: leadingWidget,
        title: Text(
          title,
          style: AppTextTheme.localizedLabel(
            isMalayalam: isMalayalam,
            color: theme.textTheme.bodyMedium?.color,
            fontSize: theme.textTheme.bodyMedium?.fontSize ?? 14,
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
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _DrawerExpansionTile extends StatelessWidget {
  const _DrawerExpansionTile({
    required this.title,
    required this.icon,
    required this.children,
    this.isMalayalam = false,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool isMalayalam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final accentColor = appBarAccentColor(context);

    return ExpansionTile(
      leading: Icon(icon, color: accentColor, size: 22 * scale),
      title: Text(
        title,
        style: AppTextTheme.localizedLabel(
          isMalayalam: isMalayalam,
          color: theme.textTheme.bodyMedium?.color,
          fontSize: theme.textTheme.bodyMedium?.fontSize ?? 14,
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
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      dense: true,
      visualDensity: VisualDensity.compact,
      children: children,
    );
  }
}

class _DrawerSubTile extends StatelessWidget {
  const _DrawerSubTile({
    required this.title,
    required this.icon,
    this.onTap,
    this.isMalayalam = false,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isMalayalam;

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
        style: AppTextTheme.localizedBody(
          isMalayalam: isMalayalam,
          color: theme.textTheme.bodyMedium?.color,
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
      visualDensity: const VisualDensity(vertical: -4),
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
      leading: Text(
        '•',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
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
      contentPadding: EdgeInsets.only(left: 56 * scale, right: 16 * scale),
      minLeadingWidth: 12 * scale,
      horizontalTitleGap: 6 * scale,
      dense: true,
      visualDensity: const VisualDensity(vertical: -4),
    );
  }
}
