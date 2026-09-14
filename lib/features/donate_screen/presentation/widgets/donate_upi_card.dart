import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';

/// The UPI QR code, as the India-only alternative to PayPal and bank
/// transfer -- scanning it needs no typing, unlike the bank details.
class DonateUpiCard extends StatelessWidget {
  const DonateUpiCard({
    super.key,
    required this.bodyColor,
    required this.isDark,
  });

  final Color bodyColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white10 : theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: isDark ? 0.4 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DonateInfo.upiHeading,
              style: AppTextTheme.englishDefault(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: bodyColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/upi_qr_code.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'UPI ID',
            style: AppTextTheme.englishDefault(
              fontSize: 12,
              color: bodyColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            DonateInfo.upiId,
            style: AppTextTheme.englishDefault(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            DonateInfo.upiNote,
            textAlign: TextAlign.center,
            style: AppTextTheme.englishDefault(
              fontSize: 12,
              color: bodyColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
