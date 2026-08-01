import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/link_hover/hover_link.dart';
import 'package:url_launcher/url_launcher.dart';

/// Compact copyright + "Powered by D4DX" strip.
///
/// By default this is pinned at the bottom of the screen via
/// [BaseScreenLayout]'s `bottomNavigationBar` slot ([fullBleed] true, full
/// width background/border strip). Pass [fullBleed] false and a [maxWidth]
/// to instead render it inline as the last item of a scrollable page,
/// sized to match a specific content container (e.g. the web home screen's
/// index/browse panel) rather than the full viewport.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key, this.fullBleed = true, this.maxWidth});

  final bool fullBleed;
  final double? maxWidth;

  static const String _copyrightText =
      "© 2026 Message of the Qur'an. All rights reserved.";

  Future<void> _launchWebsite() async {
    final uri = Uri.parse(ApiConstants.d4dxWebsiteUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint('App footer: failed to launch website');
      }
    } catch (error) {
      debugPrint('App footer: failed to launch website - $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The copyright strip sits on the brand-primary bar, so its text is white
    // regardless of the active theme.
    const footerColor = Colors.white;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentMaxWidth =
        maxWidth ??
        (kIsWeb ? 1180.0 : ResponsiveHelper.contentMaxWidth(context));
    final horizontalPadding = kIsWeb ? (screenWidth < 640 ? 12.0 : 24.0) : 12.0;

    // Wraps a strip's content so it lines up with the rest of the page:
    // capped at the content width and inset by the page gutter.
    Widget constrain(Widget child) => ConstrainedBox(
      constraints: BoxConstraints(maxWidth: contentMaxWidth),
      child: Padding(
        padding: fullBleed
            ? EdgeInsets.symmetric(horizontal: horizontalPadding)
            : EdgeInsets.zero,
        child: child,
      ),
    );

    // Links/store strip is web-only — store badges are noise inside the
    // installed app.
    final linksStrip = Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
      // Center (not Row) so the ConstrainedBox(maxWidth) actually receives the
      // real available width and shrinks on narrow screens — a Row gives
      // non-flex children unbounded main-axis constraints, which made the
      // content always claim the full 1180px and overflow.
      child: Center(
        heightFactor: 1.0,
        child: constrain(const _FooterLinksBar()),
      ),
    );

    final copyrightBar = Container(
      width: double.infinity,
      color: AppTheme.appThemePrimary,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        heightFactor: 1.0,
        child: constrain(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _copyrightText,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: footerColor,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: _PoweredByLink(onTap: _launchWebsite)),
            ],
          ),
        ),
      ),
    );

    final footer = Column(
      mainAxisSize: MainAxisSize.min,
      children: [if (kIsWeb) linksStrip, copyrightBar],
    );

    if (!fullBleed) return footer;

    // heightFactor pins the column to shrink-wrap its height instead of
    // expanding to fill the (loose but bounded) height Scaffold gives
    // bottomNavigationBar, which was pushing the footer to mid-screen.
    return SafeArea(
      top: false,
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: footer,
        ),
      ),
    );
  }
}

/// "Powered by D4DX Innovations LLP" credit. The company name shifts to light
/// blue while the pointer is over the link.
class _PoweredByLink extends StatefulWidget {
  const _PoweredByLink({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_PoweredByLink> createState() => _PoweredByLinkState();
}

class _PoweredByLinkState extends State<_PoweredByLink> {
  static const Color _idleColor = Colors.white;
  static const Color _hoverColor = Color(0xFF8ECBFF);

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HoverLink(
      url: ApiConstants.d4dxWebsiteUrl,
      child: Semantics(
        button: true,
        label: 'Visit D4DX website',
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    const TextSpan(text: 'Powered by '),
                    TextSpan(
                      text: 'D4DX Innovations LLP',
                      style: TextStyle(
                        color: _isHovered ? _hoverColor : _idleColor,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Web-only strip above the copyright line: page links on one side, the two
/// store badges on the other. Single row on wide viewports, stacked + wrapped
/// below [_stackBreakpoint].
class _FooterLinksBar extends StatelessWidget {
  const _FooterLinksBar();

  static const double _stackBreakpoint = 860;

  static const List<({String label, String path})> _links = [
    (label: 'Contact Us', path: '/contact-us'),
    (label: 'Feedback', path: '/feedback'),
    (label: 'Feature Request', path: '/feature-request'),
  ];

  void _go(BuildContext context, String path) {
    if (GoRouter.of(context).state.uri.path == path) return;
    context.push(path);
  }

  Future<void> _launchPrivacyPolicy() async {
    try {
      await launchUrl(
        Uri.parse(ApiConstants.privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      debugPrint('App footer: failed to launch privacy policy - $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final linkItems = <Widget>[
      for (final link in _links)
        _FooterTextLink(
          label: link.label,
          url: link.path,
          onTap: () => _go(context, link.path),
        ),
      _FooterTextLink(
        label: 'Privacy Policy',
        url: ApiConstants.privacyPolicyUrl,
        onTap: _launchPrivacyPolicy,
      ),
    ];

    final separatorColor = theme.colorScheme.outline.withValues(alpha: 0.5);
    final separatedLinks = <Widget>[];
    for (var i = 0; i < linkItems.length; i++) {
      if (i > 0) {
        separatedLinks.add(
          Text(
            '|',
            style: theme.textTheme.bodySmall?.copyWith(
              color: separatorColor,
              fontSize: 12,
            ),
          ),
        );
      }
      separatedLinks.add(linkItems[i]);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < _stackBreakpoint;

        final links = Wrap(
          alignment: stacked ? WrapAlignment.center : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 2,
          children: separatedLinks,
        );

        const badges = Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _StoreBadge(
              kind: _StoreKind.apple,
              topText: 'Available on the',
              bottomText: 'App Store',
              url: AppConstants.iosStoreUrl,
            ),
            _StoreBadge(
              kind: _StoreKind.play,
              topText: 'GET IT ON',
              bottomText: 'Google Play',
              url: AppConstants.androidStoreUrl,
            ),
          ],
        );

        if (stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [links, const SizedBox(height: 10), badges],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(child: links),
            const SizedBox(width: 16),
            badges,
          ],
        );
      },
    );
  }
}

class _FooterTextLink extends StatelessWidget {
  const _FooterTextLink({
    required this.label,
    required this.url,
    required this.onTap,
  });

  final String label;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark
        ? const Color(0xFFF2F2F7).withValues(alpha: 0.9)
        : theme.colorScheme.onSurface.withValues(alpha: 0.8);

    return HoverLink(
      url: url,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

enum _StoreKind { apple, play }

/// Code-drawn store badge (no bundled PNGs): dark pill, store mark, and the
/// standard two-line caption.
class _StoreBadge extends StatelessWidget {
  const _StoreBadge({
    required this.kind,
    required this.topText,
    required this.bottomText,
    required this.url,
  });

  final _StoreKind kind;
  final String topText;
  final String bottomText;
  final String url;

  Future<void> _launch() async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('App footer: failed to launch store url - $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HoverLink(
      url: url,
      child: Semantics(
        button: true,
        label: '$topText $bottomText',
        child: Material(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _launch,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kind == _StoreKind.apple)
                    const Icon(Icons.apple, size: 22, color: Colors.white)
                  else
                    const SizedBox(
                      width: 18,
                      height: 20,
                      child: CustomPaint(painter: _PlayLogoPainter()),
                    ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          height: 1.2,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        bottomText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Four-segment Google Play mark drawn from the shape's own vertices so no
/// asset is needed.
class _PlayLogoPainter extends CustomPainter {
  const _PlayLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const top = Offset.zero;
    final bottom = Offset(0, h);
    final centre = Offset(w * 0.62, h * 0.5);
    final tip = Offset(w, h * 0.5);
    final upperRight = Offset(w * 0.86, h * 0.29);
    final lowerRight = Offset(w * 0.86, h * 0.71);

    void fill(List<Offset> points, Color color) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    fill([top, centre, bottom], const Color(0xFF00A0FF)); // spine
    fill([top, upperRight, centre], const Color(0xFF00E676)); // top
    fill([upperRight, tip, lowerRight, centre], const Color(0xFFFF3A44)); // tip
    fill([centre, lowerRight, bottom], const Color(0xFFFFC500)); // bottom
  }

  @override
  bool shouldRepaint(covariant _PlayLogoPainter oldDelegate) => false;
}
