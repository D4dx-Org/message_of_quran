import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';

/// The direct-transfer side of the donate panel: bank details plus the UPI
/// id again as a one-tap copy, for a donor typing a transfer by hand rather
/// than scanning the QR on the other side.
class DonateBankCard extends StatelessWidget {
  const DonateBankCard({
    super.key,
    required this.bodyColor,
    required this.isDark,
  });

  final Color bodyColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dividerColor = bodyColor.withValues(alpha: 0.08);
    const rows = DonateInfo.bankDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DonateInfo.bankHeading,
          style: AppTextTheme.englishDefault(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: bodyColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          DonateInfo.bankNote,
          style: AppTextTheme.englishDefault(
            fontSize: 14,
            color: bodyColor.withValues(alpha: 0.65),
          ).copyWith(height: 1.55),
        ),
        const SizedBox(height: 24),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextTheme.englishDefault(
                    fontSize: 12,
                    color: bodyColor.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 3),
                // Selectable so an account number, IFSC or SWIFT code can be
                // copied out rather than retyped from the screen.
                SelectableText(
                  value,
                  style: AppTextTheme.englishDefault(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: bodyColor,
                  ),
                ),
                if ((label, value) != rows.last)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Divider(height: 1, color: dividerColor),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        _UpiCopyRow(bodyColor: bodyColor, isDark: isDark),
      ],
    );
  }
}

class _UpiCopyRow extends StatefulWidget {
  const _UpiCopyRow({required this.bodyColor, required this.isDark});

  final Color bodyColor;
  final bool isDark;

  @override
  State<_UpiCopyRow> createState() => _UpiCopyRowState();
}

class _UpiCopyRowState extends State<_UpiCopyRow> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(const ClipboardData(text: DonateInfo.upiId));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white10 : theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: widget.isDark ? 0.28 : 0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 20,
            color: theme.primaryColor.withValues(alpha: widget.isDark ? 0.85 : 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPI ID',
                  style: AppTextTheme.englishDefault(
                    fontSize: 11,
                    color: widget.bodyColor.withValues(alpha: 0.55),
                  ),
                ),
                Text(
                  DonateInfo.upiId,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTheme.englishDefault(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.bodyColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: FilledButton.tonalIcon(
              key: ValueKey(_copied),
              onPressed: _copy,
              icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 16),
              label: Text(_copied ? 'Copied' : 'Copy'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: AppTextTheme.englishDefault(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
