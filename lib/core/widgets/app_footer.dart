import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final footerColor = isDark
        ? const Color(0xFFF2F2F7).withValues(alpha: 0.85)
        : theme.colorScheme.outline.withValues(alpha: 0.92);
    final d4dxColor = isDark
        ? AppTheme.lightContentSurfaceBottomColor
        : AppTheme.appThemePrimary;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentMaxWidth =
        maxWidth ??
        (kIsWeb ? 1180.0 : ResponsiveHelper.contentMaxWidth(context));
    final horizontalPadding = kIsWeb
        ? (screenWidth < 640 ? 12.0 : 24.0)
        : 12.0;

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: contentMaxWidth),
      child: Padding(
        padding: fullBleed
            ? EdgeInsets.symmetric(horizontal: horizontalPadding)
            : EdgeInsets.zero,
        child: Row(
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
            Flexible(
              child: HoverLink(
                url: ApiConstants.d4dxWebsiteUrl,
                child: Semantics(
                  button: true,
                  label: 'Visit D4DX website',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _launchWebsite,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: footerColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            const TextSpan(text: 'Powered by '),
                            TextSpan(
                              text: 'D4DX',
                              style: TextStyle(color: d4dxColor),
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
            ),
          ],
        ),
      ),
    );

    final bordered = Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
      child: content,
    );

    if (!fullBleed) return bordered;

    return SafeArea(
      top: false,
      child: Container(
        color: theme.scaffoldBackgroundColor,
        // Center (not Row) so `bordered`'s ConstrainedBox(maxWidth) actually
        // receives the real available width and shrinks on narrow screens —
        // a Row gives non-flex children unbounded main-axis constraints,
        // which made the content always claim the full 1180px and overflow.
        // heightFactor pins Center to shrink-wrap its height instead of
        // expanding to fill the (loose but bounded) height Scaffold gives
        // bottomNavigationBar, which was pushing the footer to mid-screen.
        child: Center(heightFactor: 1.0, child: bordered),
      ),
    );
  }
}
