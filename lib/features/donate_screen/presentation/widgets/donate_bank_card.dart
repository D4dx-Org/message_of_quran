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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DonateInfo.bankHeading,
          style: AppTextTheme.englishDefault(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: bodyColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DonateInfo.bankNote,
          style: AppTextTheme.englishDefault(
            fontSize: 13,
            color: bodyColor.withValues(alpha: 0.7),
          ).copyWith(height: 1.5),
        ),
        const SizedBox(height: 20),
        for (final (label, value) in DonateInfo.bankDetails)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextTheme.englishDefault(
                    fontSize: 12,
                    color: bodyColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                // Selectable so an account number, IFSC or SWIFT code can be
                // copied out rather than retyped from the screen.
                SelectableText(
                  value,
                  style: AppTextTheme.englishDefault(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: bodyColor,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: widget.isDark ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.qr_code_2_outlined,
            size: 18,
            color: widget.bodyColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'UPI ID: ',
                    style: AppTextTheme.englishDefault(
                      fontSize: 13,
                      color: widget.bodyColor.withValues(alpha: 0.7),
                    ),
                  ),
                  TextSpan(
                    text: DonateInfo.upiId,
                    style: AppTextTheme.englishDefault(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.bodyColor,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _copy,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _copied ? 'Copied' : 'Copy',
              style: AppTextTheme.englishDefault(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
