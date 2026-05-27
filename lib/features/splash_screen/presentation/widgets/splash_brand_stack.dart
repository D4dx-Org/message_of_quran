import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_layout_metrics.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width * 0.72;
        final emblemWidth = SplashLayoutMetrics.emblemWidth(
          maxWidth,
          scale,
          screenHeight,
        );
        final titleWidth = SplashLayoutMetrics.titleWidth(
          maxWidth,
          scale,
          screenHeight,
        );
        final gap = SplashLayoutMetrics.brandGap(screenHeight, scale);
        final titleLift = SplashLayoutMetrics.titleLift(screenHeight, scale);

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