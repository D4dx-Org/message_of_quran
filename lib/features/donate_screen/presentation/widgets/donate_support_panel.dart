import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_message_of_the_quran/features/donate_screen/presentation/widgets/donate_bank_card.dart';
import 'package:the_message_of_the_quran/features/donate_screen/presentation/widgets/donate_pay_panel.dart';

/// Below this width the two halves stack instead of sitting side by side.
const double kDonateTwoColumnBreakpoint = 720;

/// One card split into the two ways to give: scan-to-pay (QR + PayPal) on
/// one side, bank transfer details on the other -- rather than two separate
/// boxes, so the donor reads it as a single choice between two paths.
class DonateSupportPanel extends StatelessWidget {
  const DonateSupportPanel({
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
    final theme = Theme.of(context);
    final payTint = theme.primaryColor.withValues(alpha: isDark ? 0.14 : 0.06);
    final borderColor = theme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.15);

    final payPanel = Padding(
      padding: const EdgeInsets.all(24),
      child: DonatePayPanel(
        bodyColor: bodyColor,
        selected: selected,
        controller: controller,
        onSelect: onSelect,
        onTyped: onTyped,
        amount: amount,
        amountAtTap: amountAtTap,
        inputFormatters: inputFormatters,
      ),
    );

    final bankPanel = Padding(
      padding: const EdgeInsets.all(24),
      child: DonateBankCard(bodyColor: bodyColor, isDark: isDark),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kDonateTwoColumnBreakpoint;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: borderColor)),
            child: isWide
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 4,
                          child: ColoredBox(color: payTint, child: payPanel),
                        ),
                        VerticalDivider(width: 1, color: borderColor),
                        Expanded(flex: 6, child: bankPanel),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ColoredBox(color: payTint, child: payPanel),
                      Divider(height: 1, color: borderColor),
                      bankPanel,
                    ],
                  ),
          ),
        );
      },
    );
  }
}
