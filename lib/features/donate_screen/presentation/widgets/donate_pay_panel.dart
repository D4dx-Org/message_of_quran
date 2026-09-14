import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/features/donate_screen/presentation/widgets/donate_amount_selector.dart';
import 'package:the_message_of_the_quran/features/donate_screen/presentation/widgets/donate_paypal_button.dart';

/// The scan-to-pay side of the donate panel: the UPI QR code, then the
/// amount picker and PayPal button for a donor who would rather type a card
/// number than scan.
class DonatePayPanel extends StatelessWidget {
  const DonatePayPanel({
    super.key,
    required this.bodyColor,
    required this.isDark,
    required this.selected,
    required this.controller,
    required this.onSelect,
    required this.onTyped,
    required this.amount,
    required this.amountAtTap,
    this.inputFormatters,
  });

  final Color bodyColor;
  final bool isDark;
  final int? selected;
  final TextEditingController controller;
  final void Function(int amount) onSelect;
  final VoidCallback onTyped;
  final int amount;
  final int Function() amountAtTap;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B3A5C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/upi_qr_code.png',
                width: 172,
                height: 172,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          DonateInfo.upiHeading,
          textAlign: TextAlign.center,
          style: AppTextTheme.englishDefault(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: bodyColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          DonateInfo.upiNote,
          textAlign: TextAlign.center,
          style: AppTextTheme.englishDefault(
            fontSize: 13,
            color: bodyColor.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 26),
        Divider(color: bodyColor.withValues(alpha: 0.14)),
        const SizedBox(height: 22),
        Text(
          DonateInfo.paypalEyebrow,
          textAlign: TextAlign.center,
          style: AppTextTheme.englishDefault(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: bodyColor.withValues(alpha: 0.5),
          ).copyWith(letterSpacing: 1.4),
        ),
        const SizedBox(height: 6),
        Text(
          DonateInfo.paypalHeading,
          textAlign: TextAlign.center,
          style: AppTextTheme.englishDefault(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: bodyColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          DonateInfo.paypalNote,
          textAlign: TextAlign.center,
          style: AppTextTheme.englishDefault(
            fontSize: 13,
            color: bodyColor.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 20),
        DonateAmountSelector(
          selected: selected,
          controller: controller,
          onSelect: onSelect,
          onTyped: onTyped,
          inputFormatters: inputFormatters,
        ),
        const SizedBox(height: 16),
        DonatePayPalButton(amount: amount, amountAtTap: amountAtTap),
      ],
    );
  }
}
