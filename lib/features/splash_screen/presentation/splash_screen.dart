import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/force_update_screen/presentation/force_update_screen.dart';
import 'package:the_message_of_the_quran/features/main_screen/presentation/main_screen.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_screen_layout.dart';
import 'package:the_message_of_the_quran/features/splash_screen/providers/version_check_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool get _shouldOverrideSystemUi =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _enterSplashSystemUi() {
    if (!_shouldOverrideSystemUi) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restoreDefaultSystemUi() {
    if (!_shouldOverrideSystemUi) return Future.value();
    return SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  Route<void> _buildNextRoute(VersionCheckProvider controller) {
    final nextScreen = controller.isUpdateNeeded
        ? const ForceUpdateScreen()
        : const MainScreen();

    return PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
    );
  }

  @override
  void initState() {
    super.initState();
    _enterSplashSystemUi();
    // Use addPostFrameCallback instead of Future.microtask so that
    // notifyListeners() is never called while the widget tree is locked.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller = Provider.of<VersionCheckProvider>(
        context,
        listen: false,
      );
      // Run the version check and a minimum 3-second splash display in parallel
      await Future.wait([
        controller.checkUpdate(),
        Future.delayed(const Duration(seconds: 3)),
      ]);

      if (!mounted) return;
      await _restoreDefaultSystemUi();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        _buildNextRoute(controller),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _restoreDefaultSystemUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.appThemeSplash,
        // Legacy full-image splash kept for future reference.
        /*
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Image(
            image: AssetImage('assets/images/splash-nw.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        */
        body: SplashScreenLayout(),
      ),
    );
  }
}
