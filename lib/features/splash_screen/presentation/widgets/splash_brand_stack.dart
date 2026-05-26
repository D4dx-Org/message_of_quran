import 'package:flutter/material.dart';

class SplashBrandStack extends StatelessWidget {
  const SplashBrandStack({
    super.key,
    required this.scale,
    required this.screenHeight,
  });

  final double scale;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    final compact = screenHeight < 720;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width * 0.72;
        final emblemWidth =
          (maxWidth * (compact ? 0.86 : 0.88))
            .clamp(210.0 * scale, 248.0 * scale)
                .toDouble();
        final titleWidth =
          (maxWidth * (compact ? 0.82 : 0.84))
            .clamp(214.0 * scale, 252.0 * scale)
                .toDouble();
        final gap = (compact ? 2.0 : 6.0) * scale;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/splash_logo.png',
              width: emblemWidth,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            SizedBox(height: gap),
            Image.asset(
              'assets/images/splash_text_logo.png',
              width: titleWidth,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ],
        );
      },
    );
  }
}