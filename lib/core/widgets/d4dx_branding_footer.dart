import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class D4dxBrandingFooter extends StatelessWidget {
  const D4dxBrandingFooter({
    super.key,
    this.versionLabel,
    this.showTopBorder = false,
    this.padding,
  });

  final String? versionLabel;
  final bool showTopBorder;
  final EdgeInsetsGeometry? padding;

  Future<void> _launchWebsite() async {
    final uri = Uri.parse(ApiConstants.d4dxWebsiteUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint('D4DX footer: failed to launch website');
      }
    } catch (error) {
      debugPrint('D4DX footer: failed to launch website - $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final footerColor = theme.colorScheme.outline.withValues(alpha: 0.92);

    return Container(
      padding:
          padding ??
          EdgeInsets.fromLTRB(20 * scale, 14 * scale, 20 * scale, 20 * scale),
      decoration: BoxDecoration(
        border: showTopBorder
            ? Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.8,
                  ),
                ),
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (versionLabel != null) ...[
            Text(
              versionLabel!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: footerColor),
            ),
            SizedBox(height: 16 * scale),
          ],
          Text(
            'Powered by',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: footerColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8 * scale),
          Semantics(
            button: true,
            label: 'Visit D4DX website',
            child: InkWell(
              borderRadius: BorderRadius.circular(12 * scale),
              onTap: _launchWebsite,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 8 * scale,
                ),
                child: Image.asset(
                  'assets/images/d4_logo.png',
                  height: 46 * scale,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
