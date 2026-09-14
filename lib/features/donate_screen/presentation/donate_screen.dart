import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/features/donate_screen/presentation/widgets/donate_support_panel.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  /// The free-entry field is always rupees -- the presets are the dollar
  /// quick-picks instead, so typing here is how a donor gives in INR.
  final TextEditingController _amountController = TextEditingController();

  /// Picking a preset selects it rather than paying straight away, so the
  /// donor can see on the button what they are about to send before leaving
  /// the app.
  int? _selectedUsd = DonateInfo.suggestedAmountsUsd.first;

  int? get _typedInr {
    final value = int.tryParse(_amountController.text.trim());
    return (value != null && value > 0) ? value : null;
  }

  bool get _isCustomInr => _typedInr != null;

  int get _amount =>
      _typedInr ?? _selectedUsd ?? DonateInfo.paypalDefaultAmount;

  String get _currency => _isCustomInr ? 'INR' : 'USD';

  String get _formattedAmount => _isCustomInr
      ? DonateInfo.formatAmount(_amount)
      : DonateInfo.formatUsdAmount(_amount);

  void _selectPreset(int amountUsd) {
    setState(() {
      _selectedUsd = amountUsd;
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
    final bodyColor = AppTextTheme.contentColor(context);

    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: 'Donate',
      ),
      drawer: const CommonDrawer(),
      // Card expands and scrolls inside it, the shape every other page uses:
      // opting out gave this page a different card height and corner
      // treatment from the rest of the site.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DonateInfo.heading,
                style: AppTextTheme.englishDefault(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: bodyColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                DonateInfo.intro,
                style: AppTextTheme.englishDefault(
                  fontSize: AppTextTheme.contentFontSize(context),
                  color: bodyColor,
                ).copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),
              Text(
                DonateInfo.tagline,
                style: AppTextTheme.englishDefault(
                  fontSize: AppTextTheme.contentFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: bodyColor,
                ),
              ),
              const SizedBox(height: 24),
              DonateSupportPanel(
                bodyColor: bodyColor,
                isDark: isDark,
                selected: _selectedUsd,
                controller: _amountController,
                onSelect: _selectPreset,
                onTyped: () => setState(() {}),
                formattedAmount: _formattedAmount,
                amountAtTap: () => _amount,
                currencyAtTap: () => _currency,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
