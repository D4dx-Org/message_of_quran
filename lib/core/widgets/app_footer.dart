import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Compact copyright + "Powered by D4DX" strip pinned at the bottom of every
/// screen via [BaseScreenLayout]'s `bottomNavigationBar` slot.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

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

    // Mirror BaseScreenLayout's content card width so the footer's contents
    // line up with the card above it instead of always spanning full width.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentMaxWidth = kIsWeb
        ? 1180.0
        : ResponsiveHelper.contentMaxWidth(context);
    final horizontalPadding = kIsWeb
        ? (screenWidth < 640 ? 12.0 : 24.0)
        : 12.0;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _copyrightText,
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: footerColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
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
                          child: Text(
                            'Powered by D4DX',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: footerColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
