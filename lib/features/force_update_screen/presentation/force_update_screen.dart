import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/utils/platform_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/responsive_content_wrapper.dart';
import 'package:the_message_of_the_quran/features/splash_screen/providers/version_check_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveContentWrapper(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [
                  Image.asset("assets/images/app-logo-nw.png", height: 100),
                  Text("Update Available", style: AppTextTheme.titleRegular),
                  Text(
                    "New Version",
                    style: AppTextTheme.popinsDefault(
                      color: AppTheme.appIconTheme,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/icons/warning.png",
                          scale: 1,
                          height: 30,
                          width: 30,
                        ),
                        Expanded(
                          child: Text(
                            "Mandatory Update",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                            style: AppTextTheme.drawerStyle.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "What's New",
                      style: AppTextTheme.titleRegular.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Provider.of<VersionCheckProvider>(
                          context,
                          listen: false,
                        ).message,
                        style: AppTextTheme.drawerStyle.copyWith(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
      persistentFooterDecoration: const BoxDecoration(border: Border()),
      persistentFooterButtons: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              decoration: const ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40)),
                ),
                gradient: LinearGradient(
                  colors: [AppTheme.appIconTheme, AppTheme.appThemePrimary],
                ),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final uri = PlatformHelper.publicAppUri;
                  final launchMode = PlatformHelper.isWeb
                      ? LaunchMode.platformDefault
                      : LaunchMode.externalApplication;
                  try {
                    await launchUrl(uri, mode: launchMode);
                  } catch (e) {
                    debugPrint('ForceUpdate: failed to launch update URL — $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  "Update Now",
                  style: AppTextTheme.title.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
