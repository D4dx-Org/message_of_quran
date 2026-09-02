import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';

/// The direct transfer details, as the alternative to PayPal.
class DonateBankCard extends StatelessWidget {
  const DonateBankCard({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DonateInfo.bankHeading,
            style: AppTextTheme.popinsDefault(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 14),
          for (final (label, value) in DonateInfo.bankDetails)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextTheme.popinsDefault(
                      fontSize: 12,
                      color: bodyColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Selectable so an account number, IFSC or SWIFT code can be
                  // copied out rather than retyped from the screen.
                  SelectableText(
                    value,
                    style: AppTextTheme.popinsDefault(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: bodyColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
