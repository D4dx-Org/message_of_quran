import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final TextEditingController _amountController = TextEditingController();

  /// What the PayPal button should ask for: whatever was typed, else the
  /// default. PayPal's page keeps it editable, but a donor should be able to
  /// set the figure here rather than having to correct it over there.
  int get _chosenAmount {
    final typed = int.tryParse(_amountController.text.trim());
    if (typed != null && typed > 0) return typed;
    return DonateInfo.paypalDefaultAmount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;

    return BaseScreenLayout(
      appBar: AppBar(
        title: Text('Donate', style: AppTextTheme.titleRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DonateInfo.heading,
                style: AppTextTheme.popinsDefault(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: bodyColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                DonateInfo.intro,
                style: AppTextTheme.popinsDefault(
                  fontSize: 15,
                  color: bodyColor,
                ).copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),
              Text(
                DonateInfo.tagline,
                style: AppTextTheme.popinsDefault(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: bodyColor,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  for (final amount in DonateInfo.suggestedAmounts) ...[
                    Expanded(child: _AmountButton(amount: amount)),
                    if (amount != DonateInfo.suggestedAmounts.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _CustomAmountField(controller: _amountController),
              const SizedBox(height: 10),
              Text(
                DonateInfo.amountsNote,
                style: AppTextTheme.popinsDefault(
                  fontSize: 13,
                  color: bodyColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              _PayPalButton(amountAtTap: () => _chosenAmount),
              const SizedBox(height: 24),
              _BankCard(bodyColor: bodyColor, isDark: isDark),
              const SizedBox(height: 16),
              Text(
                DonateInfo.bankNote,
                style: AppTextTheme.popinsDefault(
                  fontSize: 13,
                  color: bodyColor.withValues(alpha: 0.8),
                ).copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({required this.bodyColor, required this.isDark});

  final Color bodyColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : theme.primaryColor.withValues(alpha: 0.05),
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

/// PayPal's own button styling — the yellow pill donors recognise — rather
/// than our theme colours, so it reads as the PayPal route out of the page.
class _PayPalButton extends StatelessWidget {
  const _PayPalButton({required this.amountAtTap});

  /// Read when the button is pressed, not when it is built: typing in the
  /// amount field does not rebuild this widget, so a value captured at build
  /// time would always be the default.
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SizedBox(
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
              const Icon(
                SimpleIcons.paypal,
                size: 20,
                color: _payPalNavy,
              ),
              const SizedBox(width: 10),
              Text(
                DonateInfo.paypalLabel,
                style: AppTextTheme.popinsDefault(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _payPalNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the payment app with the amount already filled in — UPI when a VPA
/// is configured and the device can handle the scheme, PayPal otherwise.
class _AmountButton extends StatelessWidget {
  const _AmountButton({required this.amount});

  final int amount;

  Future<void> _pay() async {
    if (DonateInfo.upiId.isNotEmpty) {
      final upi = Uri.parse(DonateInfo.upiUrlFor(amount));
      if (await canLaunchUrl(upi)) {
        await launchUrl(upi, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final paypal = Uri.parse(DonateInfo.paypalUrlFor(amount));
    if (await canLaunchUrl(paypal)) {
      await launchUrl(paypal, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black87;
    // Plain card with a light border, the amount over its currency — the
    // shape PayPal's own donate page uses.
    return OutlinedButton(
      onPressed: _pay,
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? Colors.white10 : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        side: BorderSide(
          color: isDark ? Colors.white24 : const Color(0xFFDDDDDD),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DonateInfo.formatAmount(amount),
            style: AppTextTheme.popinsDefault(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          Text(
            'INR',
            style: AppTextTheme.popinsDefault(
              fontSize: 10,
              color: labelColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets a donor set their own figure before leaving the app, instead of
/// having to correct the amount on PayPal's page.
class _CustomAmountField extends StatelessWidget {
  const _CustomAmountField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black87;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: AppTextTheme.popinsDefault(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: labelColor,
        ),
        decoration: InputDecoration(
          isDense: true,
          prefixText: '₹ ',
          hintText: 'Other amount',
          hintStyle: AppTextTheme.popinsDefault(
            fontSize: 14,
            color: labelColor.withValues(alpha: 0.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : const Color(0xFFDDDDDD),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : const Color(0xFFDDDDDD),
            ),
          ),
        ),
      ),
    );
  }
}
