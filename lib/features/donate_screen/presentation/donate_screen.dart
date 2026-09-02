import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/donate_screen/presentation/widgets/donate_amount_selector.dart';
import 'package:the_message_of_the_quran/features/donate_screen/presentation/widgets/donate_bank_card.dart';
import 'package:the_message_of_the_quran/features/donate_screen/presentation/widgets/donate_paypal_button.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final TextEditingController _amountController = TextEditingController();

  /// Picking an amount selects it rather than paying straight away, so the
  /// donor can see on the button what they are about to send before leaving
  /// the app.
  int? _selected = DonateInfo.suggestedAmounts.first;

  int? get _typed {
    final value = int.tryParse(_amountController.text.trim());
    return (value != null && value > 0) ? value : null;
  }

  int get _amount => _typed ?? _selected ?? DonateInfo.paypalDefaultAmount;

  void _selectPreset(int amount) {
    setState(() {
      _selected = amount;
      _amountController.clear();
    });
    FocusScope.of(context).unfocus();
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kDonateContentMaxWidth),
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
                const SizedBox(height: 24),
                DonateAmountSelector(
                  selected: _selected,
                  controller: _amountController,
                  onSelect: _selectPreset,
                  onTyped: () => setState(() {}),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 18),
                DonatePayPalButton(
                  amount: _amount,
                  amountAtTap: () => _amount,
                ),
                const SizedBox(height: 24),
                DonateBankCard(bodyColor: bodyColor, isDark: isDark),
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
      ),
    );
  }
}
