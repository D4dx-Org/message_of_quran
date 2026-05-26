import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_bottom_branding.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_brand_stack.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_header_overlay.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_layout_metrics.dart';

class SplashScreenLayout extends StatelessWidget {
  const SplashScreenLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final scale = ResponsiveHelper.scaleFactor(context);
        final viewPadding = MediaQuery.viewPaddingOf(context);
        final horizontalPadding = (size.width * 0.09).clamp(24.0, 40.0).toDouble();
        final bottomReserved = SplashLayoutMetrics.bottomReserved(
          size.width,
          viewPadding.bottom,
        );
        final topReserved = SplashLayoutMetrics.topReserved(
          viewPadding.top,
          scale,
        );
        final contentMaxWidth =
            (size.width * 0.72)
                .clamp(280.0, 336.0 * scale)
                .toDouble();

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppTheme.appThemeSplash),
            Positioned.fill(
              child: Image.asset(
                'assets/images/main_splash.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x12000000),
                      Color(0x00000000),
                      Color(0x7A000000),
                    ],
                    stops: [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
            SplashHeaderOverlay(
              scale: scale,
              topInset: viewPadding.top,
              availableWidth: size.width,
            ),
            Align(
              alignment: const Alignment(0, -0.02),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topReserved,
                  horizontalPadding,
                  bottomReserved,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: SplashBrandStack(
                    scale: scale,
                    screenHeight: size.height,
                  ),
                ),
              ),
            ),
            SplashBottomBranding(
              scale: scale,
              bottomInset: viewPadding.bottom,
              screenHeight: size.height,
              screenWidth: size.width,
            ),
          ],
        );
      },
    );
  }
}