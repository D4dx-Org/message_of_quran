import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/responsive_content_wrapper.dart';

/// A reusable screen layout that provides the app's signature UI pattern:
/// brown background with a rounded white/cream content card.
///
/// Used across all screens (except Splash and Force Update) to maintain
/// visual consistency during navigation.
class BaseScreenLayout extends StatelessWidget {
  const BaseScreenLayout({
    super.key,
    required this.child,
    this.appBar,
    this.headerContent,
    this.contentCardBoxShadows,
    this.floatingActionButton,
    this.drawer,
    this.useScaffold = true,
    this.topBorderRadius = 40,
    this.endDrawer,
    this.resizeToAvoidBottomInset,
  });

  /// The main content displayed inside the rounded card area.
  final Widget child;

  /// Optional AppBar for the screen.
  final PreferredSizeWidget? appBar;

  /// Optional content displayed in the brown area above the rounded card
  /// (e.g. chip rows, section headers).
  final Widget? headerContent;

  /// Optional shadow override for the rounded content card.
  final List<BoxShadow>? contentCardBoxShadows;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Optional drawer.
  final Widget? drawer;

  /// Optional end drawer.
  final Widget? endDrawer;

  /// Whether to wrap in a Scaffold. Set to `false` for screens that are
  /// already embedded inside another Scaffold (e.g. IndexedStack tabs).
  final bool useScaffold;

  /// The border radius for the top corners of the content card.
  final double topBorderRadius;

  /// Whether the body should resize when the keyboard appears.
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    final theme = Theme.of(context);

    if (!useScaffold) return body;

    return Scaffold(
      backgroundColor: kIsWeb
          ? theme.scaffoldBackgroundColor
          : AppTheme.appThemePrimary,
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final useDesktopWebShell = kIsWeb;
    final webCardBorderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant);

    if (useDesktopWebShell) {
      final width = MediaQuery.sizeOf(context).width;
      final horizontalPadding = width < 640 ? 12.0 : 24.0;
      final verticalPadding = width < 640 ? 16.0 : 24.0;

      return SafeArea(
        top: false,
        child: ResponsiveContentWrapper(
          maxWidth: 1180,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            children: [
              if (headerContent != null) ...[
                headerContent!,
                SizedBox(height: width < 640 ? 16 : 20),
              ],
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(topBorderRadius),
                      topRight: Radius.circular(topBorderRadius),
                    ),
                    gradient: isDarkMode
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(255, 255, 255, 1),
                              Color.fromRGBO(255, 250, 234, 1),
                            ],
                          ),
                    color: isDarkMode ? const Color(0xff0c2d52) : null,
                            border: Border.all(color: webCardBorderColor),
                    boxShadow:
                        contentCardBoxShadows ??
                        const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.25),
                            blurRadius: 4,
                            offset: Offset(0, -2),
                          ),
                        ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: ResponsiveContentWrapper(
        child: Column(
          children: [
            if (headerContent != null) headerContent!,
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(topBorderRadius),
                    topRight: Radius.circular(topBorderRadius),
                  ),
                  gradient: isDarkMode
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromRGBO(255, 255, 255, 1),
                            Color.fromRGBO(255, 250, 234, 1),
                          ],
                        ),
                  color: isDarkMode ? const Color(0xff0c2d52) : null,
                  boxShadow:
                      contentCardBoxShadows ??
                      const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.25),
                          blurRadius: 4,
                          offset: Offset(0, -2),
                        ),
                      ],
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
