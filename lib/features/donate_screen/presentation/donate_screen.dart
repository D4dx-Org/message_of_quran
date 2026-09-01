import 'package:flutter/material.dart';
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
        child: SingleChildScrollView(
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        amount,
                        style: AppTextTheme.popinsDefault(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: bodyColor,
                        ),
                      ),
                    ),
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
