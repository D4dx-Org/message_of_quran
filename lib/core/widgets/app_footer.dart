import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
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

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            Flexible(
              child: Text(
                _copyrightText,
                textAlign: TextAlign.center,
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
    );
  }
}
