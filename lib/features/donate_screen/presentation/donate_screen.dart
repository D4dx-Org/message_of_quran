import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;

    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: 'Donate',
      ),
      drawer: const CommonDrawer(),
      expandContentCard: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        // No scroll view here: with expandContentCard false BaseScreenLayout
        // scrolls the page itself, and a second one would put a scrollbar
        // inside the card that no other page has.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              DonateInfo.heading,
              style: AppTextTheme.popinsDefault(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: bodyColor,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              DonateInfo.intro,
              style: AppTextTheme.popinsDefault(
                fontSize: 15,
                color: bodyColor,
              ).copyWith(height: 1.6),
            ),
            const SizedBox(height: 16),
            SelectableText(
              DonateInfo.tagline,
              style: AppTextTheme.popinsDefault(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: bodyColor,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final amount in DonateInfo.suggestedAmounts)
                  _AmountButton(amount: amount),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              DonateInfo.amountsNote,
              style: AppTextTheme.popinsDefault(
                fontSize: 13,
                color: bodyColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            const _PayPalButton(),
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
      constraints: const BoxConstraints(maxWidth: 560),
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
  const _PayPalButton();

  static const Color _payPalYellow = Color(0xFFFFC439);
  static const Color _payPalNavy = Color(0xFF003087);

  Future<void> _open() async {
    final uri = Uri.parse(
      DonateInfo.paypalUrlFor(DonateInfo.paypalDefaultAmount),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          Text(
            'INR',
            style: AppTextTheme.popinsDefault(
              fontSize: 12,
              color: labelColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
