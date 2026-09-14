import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';

/// PayPal's own button styling — the yellow pill donors recognise — rather
/// than our theme colours, so it reads as the PayPal route out of the page.
/// Matches PayPal's published button spec: #FFC439 fill, #001C64 label, a
/// soft navy-tinted shadow, and the official two-tone "PP" monogram traced
/// from PayPal's own exported vector, not a hand-drawn approximation.
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
  static const Color _payPalLabel = Color(0xFF001C64);

  Future<void> _open() async {
    final uri = Uri.parse(DonateInfo.paypalUrlFor(amountAtTap()));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001C64).withValues(alpha: 0.141176),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _open,
        style: ElevatedButton.styleFrom(
          backgroundColor: _payPalYellow,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/paypal_mark.svg',
              width: 18,
              height: 22,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Donate ${DonateInfo.formatAmount(amount)} with PayPal',
                overflow: TextOverflow.ellipsis,
                style: AppTextTheme.englishDefault(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _payPalLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
