import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/constants/useful_links.dart';
import 'package:the_message_of_the_quran/core/routing/app_router.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/d4dx_branding_footer.dart';
import 'package:the_message_of_the_quran/core/widgets/link_hover/hover_link.dart';
import 'package:the_message_of_the_quran/core/widgets/shimmer_asset_image.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';
import 'package:the_message_of_the_quran/core/utils/platform_helper.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Navigates to a drawer destination while keeping the root navigator stack
/// at most two pages deep: [Home, destination]. The first hop from Home
/// pushes (so Home stays underneath); any hop from an already-pushed drawer
/// page replaces it instead of stacking further, so the back button always
/// lands on Home rather than the previously visited drawer page. Tapping the
/// drawer item for the screen already showing is a no-op — otherwise
/// pushReplacement would still swap in a fresh instance of the same screen.
void _navigateFromDrawer(BuildContext context, String path) {
  if (GoRouter.of(context).state.uri.path == path) return;

  final canPop = rootNavigatorKey.currentState?.canPop() ?? false;
  if (canPop) {
    context.pushReplacement(path);
  } else {
    context.push(path);
  }
}

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
              const _DrawerBrandHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: 1 * scale, bottom: 8 * scale),
                  child: Column(
                    children: [
                      _DrawerTile(
                        title: 'Home',
                        icon: Icons.home_outlined,
                        assetPath: 'assets/icons/home-img.png',
                        url: '/',
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/');
                        },
                      ),
                      _DrawerTile(
                        title: isMalayalam ? 'പ്രിയപ്പെട്ടവ' : 'Favourites',
                        icon: Icons.favorite_border_rounded,
                        isMalayalam: isMalayalam,
                        url: '/favorites',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateFromDrawer(context, '/favorites');
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
                              url: '/author',
                              onTap: () {
                                Navigator.pop(context);
                                _navigateFromDrawer(context, '/author');
                              },
                            ),
                            _DrawerSubTile(
                              title: 'വിവർത്തകൻ',
                              icon: Icons.translate_outlined,
                              isMalayalam: true,
                              url: '/translator',
                              onTap: () {
                                Navigator.pop(context);
                                _navigateFromDrawer(context, '/translator');
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
                              url: '/author',
                              onTap: () {
                                Navigator.pop(context);
                                _navigateFromDrawer(context, '/author');
                              },
                            ),
                            _DrawerSubTile(
                              title: 'Translator',
                              icon: Icons.translate_outlined,
                              url: '/translator-en',
                              onTap: () {
                                Navigator.pop(context);
                                _navigateFromDrawer(context, '/translator-en');
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
                            url: '/foreword',
                            onTap: () {
                              Navigator.pop(context);
                              _navigateFromDrawer(context, '/foreword');
                            },
                          ),
                          _DrawerSubTile(
                            title: isMalayalam ? 'അനുബന്ധം' : 'Appendix',
                            icon: Icons.note_alt_outlined,
                            isMalayalam: isMalayalam,
                            url: '/appendix',
                            onTap: () {
                              Navigator.pop(context);
                              _navigateFromDrawer(context, '/appendix');
                            },
                          ),
                          if (!isMalayalam)
                            _DrawerSubTile(
                              title: 'Works of Reference',
                              icon: Icons.library_books_outlined,
                              url: '/works-of-reference',
                              onTap: () {
                                Navigator.pop(context);
                                _navigateFromDrawer(
                                  context,
                                  '/works-of-reference',
                                );
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
                        url: '/prostration-verses',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateFromDrawer(context, '/prostration-verses');
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
                                internalIsMalayalam: link.internalIsMalayalam,
                              ),
                          ],
                        ),
                      _DrawerTile(
                        title: 'Compare Translations',
                        icon: Icons.compare_arrows_rounded,
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await launchUrl(
                              Uri.parse(AppConstants.compareTranslationsUrl),
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            debugPrint(
                              'Drawer: failed to launch compare translations URL — $e',
                            );
                          }
                        },
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
                        title: 'Donate',
                        icon: Icons.volunteer_activism_outlined,
                        url: '/donate',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateFromDrawer(context, '/donate');
                        },
                      ),
                      _DrawerTile(
                        title: 'Feedback',
                        icon: Icons.mail_outline,
                        url: '/feedback',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateFromDrawer(context, '/feedback');
                        },
                      ),
                      _DrawerTile(
                        title: 'Feature Request',
                        icon: Icons.lightbulb_outline_rounded,
                        url: '/feature-request',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateFromDrawer(context, '/feature-request');
                        },
                      ),
                      _DrawerTile(
                        title: 'Contact Us',
                        icon: Icons.chat_bubble_outline,
                        url: '/contact-us',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateFromDrawer(context, '/contact-us');
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
                          // The link comes first, on its own, so WhatsApp
                          // and similar apps reliably unfurl it into a rich
                          // preview card (title/description/icon) instead of
                          // showing plain text — this breaks when a URL is
                          // buried after other text or multiple links share
                          // one message. It's the website link rather than a
                          // direct store link because Google blocks
                          // WhatsApp's preview bot from reading Play Store
                          // pages' metadata (confirmed: even a bare Play
                          // Store link typed directly into WhatsApp shows no
                          // title/icon, only the raw URL) — the store links
                          // still follow below for the recipient to tap.
                          final buffer = StringBuffer()
                            ..writeln(AppConstants.webEditionUrl)
                            ..writeln()
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
                      )
                      else
                      _DrawerTile(
                        title: 'Share Web',
                        icon: Icons.share_outlined,
                        onTapWithContext: (tileContext) async {
                          final sharePositionOrigin =
                              _sharePositionOriginFor(tileContext);
                          Navigator.pop(context);
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );
                          final buffer = StringBuffer()
                            ..writeln(AppConstants.webEditionUrl)
                            ..writeln()
                            ..writeln(
                              'Check out Quran Asad Malayalam – a beautiful Quran reader with Malayalam translation.',
                            );
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
                      HoverLink(
                        url: ApiConstants.privacyPolicyUrl,
                        child: _DrawerTile(
                          title: 'Privacy',
                          icon: Icons.shield_outlined,
                          onTap: () {
                            try {
                              launchUrl(
                                Uri.parse(ApiConstants.privacyPolicyUrl),
                              );
                            } catch (e) {
                              debugPrint(
                                'Drawer: failed to launch privacy URL — $e',
                              );
                            }
                          },
                        ),
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
  const _DrawerBrandHeader();

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
    this.url,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Future<void> Function(BuildContext context)? onTapWithContext;
  final String? assetPath;
  final bool isMalayalam;
  final String? url;

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

    final tile = Builder(
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

    return url != null ? HoverLink(url: url!, child: tile) : tile;
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
    this.url,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isMalayalam;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final accentColor = appBarAccentColor(context);

    final tile = ListTile(
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

    return url != null ? HoverLink(url: url!, child: tile) : tile;
  }
}



class _DrawerLinkTile extends StatelessWidget {
  const _DrawerLinkTile({
    required this.title,
    required this.url,
    this.internalIsMalayalam = false,
  });

  final String title;
  final String url;
  final bool internalIsMalayalam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    // Muhammad Asad is this app's own translation, not an external site —
    // an empty url means "go to our home page" in that entry's own language
    // instead of launching a link.
    final isInternal = url.isEmpty;

    final tile = ListTile(
      onTap: () async {
        Navigator.pop(context);
        if (isInternal) {
          final languageProvider = context.read<LanguageProvider>();
          await languageProvider.setLanguage(
            internalIsMalayalam
                    ? LanguageProvider.malayalam
                    : LanguageProvider.english,
          );
          if (!context.mounted) return;
          _navigateFromDrawer(context, '/');
          return;
        }
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
      trailing: isInternal
          ? null
          : Icon(
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

    return isInternal ? tile : HoverLink(url: url, child: tile);
  }
}
