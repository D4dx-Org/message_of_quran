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
    required this.selected,
    required this.controller,
    required this.onSelect,
    required this.onTyped,
    required this.amount,
    required this.amountAtTap,
    this.inputFormatters,
  });

  final Color bodyColor;
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
          DonateInfo.upiHeading,
          textAlign: TextAlign.center,
          style: AppTextTheme.englishDefault(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: bodyColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DonateInfo.upiNote,
          textAlign: TextAlign.center,
          style: AppTextTheme.englishDefault(
            fontSize: 12,
            color: bodyColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 22),
        Divider(color: bodyColor.withValues(alpha: 0.15)),
        const SizedBox(height: 18),
        Text(
          DonateInfo.paypalHeading,
          textAlign: TextAlign.center,
          style: AppTextTheme.englishDefault(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: bodyColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DonateInfo.paypalNote,
          textAlign: TextAlign.center,
          style: AppTextTheme.englishDefault(
            fontSize: 12,
            color: bodyColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        DonateAmountSelector(
          selected: selected,
          controller: controller,
          onSelect: onSelect,
          onTyped: onTyped,
          inputFormatters: inputFormatters,
        ),
        const SizedBox(height: 14),
        DonatePayPalButton(amount: amount, amountAtTap: amountAtTap),
      ],
    );
  }
}
