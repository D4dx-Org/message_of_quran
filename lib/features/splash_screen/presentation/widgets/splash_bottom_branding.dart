import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_layout_metrics.dart';

class SplashBottomBranding extends StatelessWidget {
  const SplashBottomBranding({
    super.key,
    required this.scale,
    required this.bottomInset,
    required this.screenHeight,
    required this.screenWidth,
  });

  final double scale;
  final double bottomInset;
  final double screenHeight;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final compact = screenHeight < 720;
    final ellipseWidth = SplashLayoutMetrics.footerWidth(screenWidth);
    final ellipseHeight = SplashLayoutMetrics.footerHeight(screenWidth);
    final ellipseLeft = -(ellipseWidth - screenWidth) / 2;
    final ellipseBottom = SplashLayoutMetrics.footerBottomOffset(screenWidth);
    final footerContentAlignment =
        SplashLayoutMetrics.footerContentAlignmentY(screenHeight) -
        (bottomInset > 0 ? 0.04 : 0.0);
    final logoWidth = SplashLayoutMetrics.footerLogoWidth(screenWidth) * scale;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: ellipseLeft,
            bottom: ellipseBottom,
            child: ClipOval(
              child: SizedBox(
                width: ellipseWidth,
                height: ellipseHeight,
                child: DecoratedBox(
                  decoration:  BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SplashLayoutMetrics.footerFillTop,
                        SplashLayoutMetrics.footerFillBottom,
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment(0, footerContentAlignment),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Powered By',
                          textAlign: TextAlign.center,
                          style: AppTextTheme.popinsDefault(
                            color: const Color(0xFFE0E5F5),
                            fontSize: (compact ? 8.0 : 8.8) * scale,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Image.asset(
                          'assets/images/d4_logo.png',
                          width: logoWidth,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                          filterQuality: FilterQuality.high,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
