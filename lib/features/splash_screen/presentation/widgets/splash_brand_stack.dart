import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_layout_metrics.dart';

class SplashBrandStack extends StatelessWidget {
  static const double _emblemHeightFactor = 1.0;
  static const double _titleHeightFactor = 564 / 1254;

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
        final naturalHeight =
            (emblemWidth * _emblemHeightFactor) +
            gap +
            (titleWidth * _titleHeightFactor);
        final heightScale = constraints.maxHeight.isFinite &&
                constraints.maxHeight > 0 &&
                naturalHeight > constraints.maxHeight
            ? (constraints.maxHeight / naturalHeight).clamp(0.0, 1.0).toDouble()
            : 1.0;
        final fittedEmblemWidth = emblemWidth * heightScale;
        final fittedTitleWidth = titleWidth * heightScale;
        final fittedGap = gap * heightScale;
        final fittedTitleLift = titleLift * heightScale;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/symbol-logo.webp',
              width: fittedEmblemWidth,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            SizedBox(height: fittedGap),
            Transform.translate(
              offset: Offset(0, -fittedTitleLift),
              child: Image.asset(
                'assets/images/symbol-logo-text.webp',
                width: fittedTitleWidth,
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