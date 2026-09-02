import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';

/// Keeps the donate column from stretching into slabs on a wide screen.
const double kDonateContentMaxWidth = 560;

/// The preset amounts and the free-entry field, as one control.
///
/// Presets select rather than pay, so the amount can be checked on the donate
/// button before the donor leaves the app, and typing a figure clears the
/// preset so only one of the two is ever shown as chosen.
class DonateAmountSelector extends StatelessWidget {
  const DonateAmountSelector({
    super.key,
    required this.selected,
    required this.controller,
    required this.onSelect,
    required this.onTyped,
    this.inputFormatters,
  });

  final int? selected;
  final TextEditingController controller;
  final void Function(int amount) onSelect;
  final VoidCallback onTyped;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black87;
    final hasTyped = controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose an amount',
          style: AppTextTheme.popinsDefault(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final amount in DonateInfo.suggestedAmounts) ...[
              Expanded(
                child: _AmountChip(
                  amount: amount,
                  selected: !hasTyped && selected == amount,
                  onTap: () => onSelect(amount),
                ),
              ),
              if (amount != DonateInfo.suggestedAmounts.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: inputFormatters,
          onChanged: (_) => onTyped(),
          style: AppTextTheme.popinsDefault(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Text(
                '₹',
                style: AppTextTheme.popinsDefault(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: labelColor.withValues(alpha: 0.7),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            hintText: 'Enter another amount',
            hintStyle: AppTextTheme.popinsDefault(
              fontSize: 14,
              color: labelColor.withValues(alpha: 0.45),
            ),
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: _fieldBorder(isDark, theme, focused: false),
            enabledBorder: _fieldBorder(isDark, theme, focused: false),
            focusedBorder: _fieldBorder(isDark, theme, focused: true),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder(
    bool isDark,
    ThemeData theme, {
    required bool focused,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: focused
            ? theme.primaryColor
            : (isDark ? Colors.white24 : const Color(0xFFE0E0E0)),
        width: focused ? 1.6 : 1,
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor =
        selected ? theme.primaryColor : (isDark ? Colors.white : Colors.black87);

    return Material(
      color: selected
          ? theme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.08)
          : (isDark ? Colors.white10 : Colors.white),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.primaryColor
                  : (isDark ? Colors.white24 : const Color(0xFFE0E0E0)),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Center(
            // Shrinks rather than wraps, so ₹1,000 still fits the narrowest
            // quarter of a small phone screen.
            child: FittedBox(
              child: Text(
                DonateInfo.formatAmount(amount),
                style: AppTextTheme.popinsDefault(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
