import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_message_of_the_quran/core/constants/donate_info.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';

/// PayPal's own button styling — the yellow pill donors recognise — rather
/// than our theme colours, so it reads as the PayPal route out of the page.
/// Matches PayPal's published button spec: #FFC439 fill, #001C64 label, a
/// soft navy-tinted shadow, and the official two-tone monogram.
class DonatePayPalButton extends StatelessWidget {
  const DonatePayPalButton({
    super.key,
    required this.amount,
    required this.amountAtTap,
  });

  /// Shown on the label, so the donor can see what they are about to send.
  final int amount;

  /// Read when the button is pressed rather than when it is built: typing in
  /// the amount field does not rebuild this widget, so a value captured at
  /// build time would always be the default.
  final int Function() amountAtTap;

  static const Color _payPalYellow = Color(0xFFFFC439);
  static const Color _payPalLabel = Color(0xFF001C64);

  Future<void> _open() async {
    final uri = Uri.parse(DonateInfo.paypalUrlFor(amountAtTap()));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001C64).withValues(alpha: 0.141176),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _open,
        style: ElevatedButton.styleFrom(
          backgroundColor: _payPalYellow,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PayPalMonogram(size: 24),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Donate ${DonateInfo.formatAmount(amount)} with PayPal',
                overflow: TextOverflow.ellipsis,
                style: AppTextTheme.englishDefault(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _payPalLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PayPal's official two-tone monogram: two overlapping "P" letterforms
/// where the overlap reads as the darkest of the three brand blues. Drawn
/// rather than shipped as an SVG so the overlap tone falls out of the actual
/// shape intersection instead of a fourth hand-picked color.
class _PayPalMonogram extends StatelessWidget {
  const _PayPalMonogram({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PayPalMonogramPainter()),
    );
  }
}

class _PayPalMonogramPainter extends CustomPainter {
  static const _backTone = Color(0xFF003087);
  static const _overlapTone = Color(0xFF001C64);
  static const _frontTone = Color(0xFF0070E0);

  static Path _letterP(Rect box) {
    final stemWidth = box.width * 0.34;
    final loopHeight = box.height * 0.58;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(box.left, box.top, stemWidth, box.height),
          Radius.circular(stemWidth / 2),
        ),
      );
    final loopRect = Rect.fromLTWH(
      box.left + stemWidth * 0.6,
      box.top,
      box.width - stemWidth * 0.6,
      loopHeight,
    );
    path.addRRect(
      RRect.fromRectAndRadius(loopRect, Radius.circular(loopRect.height / 2)),
    );
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final backBox = Rect.fromLTRB(
      size.width * 0.0,
      size.height * 0.0,
      size.width * 0.851,
      size.height * 0.80,
    );
    final frontBox = Rect.fromLTRB(
      size.width * 0.2105,
      size.height * 0.2292,
      size.width * 1.0,
      size.height * 1.0,
    );

    final backP = _letterP(backBox);
    final frontP = _letterP(frontBox);
    final overlap = Path.combine(PathOperation.intersect, backP, frontP);

    canvas.drawPath(backP, Paint()..color = _backTone);
    canvas.drawPath(frontP, Paint()..color = _frontTone);
    canvas.drawPath(overlap, Paint()..color = _overlapTone);
  }

  @override
  bool shouldRepaint(covariant _PayPalMonogramPainter oldDelegate) => false;
}
