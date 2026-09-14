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
    required this.formattedAmount,
    required this.amountAtTap,
    required this.currencyAtTap,
    this.inputFormatters,
  });

  final Color bodyColor;
  final bool isDark;
  final int? selected;
  final TextEditingController controller;
  final void Function(int amount) onSelect;
  final VoidCallback onTyped;
  final String formattedAmount;
  final int Function() amountAtTap;
  final String Function() currencyAtTap;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.primaryColor.withValues(alpha: isDark ? 0.28 : 0.12);
    final payGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              theme.primaryColor.withValues(alpha: 0.32),
              theme.primaryColor.withValues(alpha: 0.14),
            ]
          : [
              theme.primaryColor.withValues(alpha: 0.10),
              theme.primaryColor.withValues(alpha: 0.03),
            ],
    );

    final payPanel = Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      child: DonatePayPanel(
        bodyColor: bodyColor,
        isDark: isDark,
        selected: selected,
        controller: controller,
        onSelect: onSelect,
        onTyped: onTyped,
        formattedAmount: formattedAmount,
        amountAtTap: amountAtTap,
        currencyAtTap: currencyAtTap,
        inputFormatters: inputFormatters,
      ),
    );

    final bankPanel = Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      child: DonateBankCard(bodyColor: bodyColor, isDark: isDark),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kDonateTwoColumnBreakpoint;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: isWide
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(gradient: payGradient),
                            child: payPanel,
                          ),
                        ),
                        VerticalDivider(width: 1, color: borderColor),
                        Expanded(flex: 6, child: bankPanel),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(gradient: payGradient),
                        child: payPanel,
                      ),
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
