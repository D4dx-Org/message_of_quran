import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';

/// PayPal's own button styling — the yellow pill donors recognise — rather
/// than our theme colours, so it reads as the PayPal route out of the page.
class DonatePayPalButton extends StatelessWidget {
  const DonatePayPalButton({
    super.key,
    required this.amount,
    required this.amountAtTap,
  });

  /// Shown on the label, so the donor can see what they are about to send.
  final int amount;

  /// Read when the button is pressed rather than when it is built: typing in
  /// the amount field does not rebuild this widget, so a value captured at
  /// build time would always be the default.
  final int Function() amountAtTap;

  static const Color _payPalYellow = Color(0xFFFFC439);
  static const Color _payPalNavy = Color(0xFF003087);

  Future<void> _open() async {
    final uri = Uri.parse(DonateInfo.paypalUrlFor(amountAtTap()));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _open,
        style: ElevatedButton.styleFrom(
          backgroundColor: _payPalYellow,
          foregroundColor: _payPalNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Just the one glyph, lifted out of the icon font: shipping the
            // whole Simple Icons set for a single mark cost 1.3 MB.
            SvgPicture.asset(
              'assets/icons/paypal.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                _payPalNavy,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Donate ${DonateInfo.formatAmount(amount)} with PayPal',
                overflow: TextOverflow.ellipsis,
                style: AppTextTheme.popinsDefault(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _payPalNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
