import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_layout_metrics.dart';

class SplashHeaderOverlay extends StatelessWidget {
  const SplashHeaderOverlay({
    super.key,
    required this.scale,
    required this.topInset,
    required this.availableWidth,
  });

  final double scale;
  final double topInset;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final ornamentWidth = SplashLayoutMetrics.ornamentWidth(availableWidth);
    final headerTextTop = SplashLayoutMetrics.headerTextTop(topInset, scale);

    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              top: SplashLayoutMetrics.ornamentTop(topInset, scale),
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.52,
                  child: Image.asset(
                    'assets/images/home_side_image.png',
                    width: ornamentWidth,
                    fit: BoxFit.contain,
                    color: SplashLayoutMetrics.ornamentTint,
                    colorBlendMode: BlendMode.srcIn,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            Positioned(
              top: headerTextTop,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MUHAMMAD ASAD',
                    textAlign: TextAlign.center,
                    style: AppTextTheme.popinsDefault(
                      color: Colors.white,
                      fontSize: 17 * scale,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    'Leopold Weiss',
                    textAlign: TextAlign.center,
                    style: AppTextTheme.popinsDefault(
                      color: const Color(0xFFD6D9E2),
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}