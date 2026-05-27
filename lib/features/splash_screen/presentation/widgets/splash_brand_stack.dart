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
          (maxWidth * (compact ? 1.16 : 1.18))
            .clamp(266.0 * scale, 328.0 * scale)
                .toDouble();
        final titleWidth =
          (maxWidth * (compact ? 0.94 : 0.96))
            .clamp(236.0 * scale, 286.0 * scale)
                .toDouble();
        final gap = (compact ? 0.0 : 1.0) * scale;
        final titleLift = (compact ? 8.0 : 10.0) * scale;

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
            Transform.translate(
              offset: Offset(0, -titleLift),
              child: Image.asset(
                'assets/images/splash_text_logo.png',
                width: titleWidth,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        );
      },
    );
  }
}