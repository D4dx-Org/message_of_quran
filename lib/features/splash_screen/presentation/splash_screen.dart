import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/force_update_screen/presentation/force_update_screen.dart';
import 'package:the_message_of_the_quran/features/main_screen/presentation/main_screen.dart';
import 'package:the_message_of_the_quran/features/splash_screen/providers/version_check_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => controller.isUpdateNeeded
              ? const ForceUpdateScreen()
              : const MainScreen(),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.appThemeSplash,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image(
          image: AssetImage('assets/images/splash-nw.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
