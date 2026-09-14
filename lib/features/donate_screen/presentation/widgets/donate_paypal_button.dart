import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';

/// The PayPal donate button, styled in the app's own navy/white rather than
/// PayPal's yellow branding, so it reads as part of this page instead of a
/// jarringly different-colored block dropped into it. The monogram keeps its
/// real brand colors (in a small white chip, so they stay legible against the
/// navy fill) since that's what makes it recognizable as "pay with PayPal";
/// everything else -- fill, text, shadow -- follows the site's own palette.
class DonatePayPalButton extends StatelessWidget {
  const DonatePayPalButton({
    super.key,
    required this.formattedAmount,
    required this.amountAtTap,
    required this.currencyAtTap,
  });

  /// Already-formatted for its currency ("$10" or "₹500"), shown on the
  /// label so the donor can see what they are about to send.
  final String formattedAmount;

  /// Read when the button is pressed rather than when it is built: typing in
  /// the amount field does not rebuild this widget, so a value captured at
  /// build time would always be the default.
  final int Function() amountAtTap;

  /// The ISO currency code ('USD' for a preset, 'INR' for a typed amount),
  /// read at tap time for the same reason as [amountAtTap].
  final String Function() currencyAtTap;

  Future<void> _open() async {
    final uri = Uri.parse(
      DonateInfo.paypalUrlFor(amountAtTap(), currency: currencyAtTap()),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _open,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SvgPicture.asset(
                'assets/icons/paypal_mark.svg',
                width: 15,
                height: 18,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Donate $formattedAmount with PayPal',
                overflow: TextOverflow.ellipsis,
                style: AppTextTheme.englishDefault(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
