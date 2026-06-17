import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/responsive_content_wrapper.dart';

const _baseScreenLayoutBottomSafeAreaFillKey = Key(
  'baseScreenLayoutBottomSafeAreaFill',
);
const _baseScreenLayoutContentInsetPaddingKey = Key(
  'baseScreenLayoutContentInsetPadding',
);

/// A reusable screen layout that provides the app's signature UI pattern:
/// brown background with a rounded white/cream content card.
///
/// Used across all screens (except Splash and Force Update) to maintain
/// visual consistency during navigation.
class BaseScreenLayout extends StatelessWidget {
  static const double defaultContentTopInset = 10;

  const BaseScreenLayout({
    super.key,
    required this.child,
    this.appBar,
    this.headerContent,
    this.contentCardBoxShadows,
    this.floatingActionButton,
    this.drawer,
    this.useScaffold = true,
    this.topBorderRadius,
    this.bottomBorderRadius,
    this.endDrawer,
    this.resizeToAvoidBottomInset,
    this.contentTopInset = defaultContentTopInset,
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
  /// Defaults to `18` on desktop/web and `40` on mobile.
  final double? topBorderRadius;

  /// The border radius for the bottom corners of the content card.
  /// Defaults to the desktop/web top radius and `0` on mobile.
  final double? bottomBorderRadius;

  /// Whether the body should resize when the keyboard appears.
  final bool? resizeToAvoidBottomInset;

  /// The top inset applied inside the rounded content card before [child].
  final double contentTopInset;

  static const _lightContentSurfaceBottomColor = Color.fromRGBO(
    255,
    250,
    234,
    1,
  );
  static const _darkContentSurfaceColor = Color(0xff0c2d52);

  BoxDecoration _buildContentCardDecoration({
    required bool isDarkMode,
    required BorderRadius borderRadius,
    Color? borderColor,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius,
      gradient: isDarkMode
          ? null
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(255, 255, 255, 1),
                _lightContentSurfaceBottomColor,
              ],
            ),
      color: isDarkMode ? _darkContentSurfaceColor : null,
      border: borderColor != null ? Border.all(color: borderColor) : null,
      boxShadow:
          contentCardBoxShadows ??
          const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.25),
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
    );
  }

  Color _contentSurfaceColor({required bool isDarkMode}) {
    return isDarkMode
        ? _darkContentSurfaceColor
        : _lightContentSurfaceBottomColor;
  }

  Widget _buildContentCardChild() {
    Widget content = contentTopInset == 0
        ? child
        : Padding(
            key: _baseScreenLayoutContentInsetPaddingKey,
            padding: EdgeInsets.only(top: contentTopInset),
            child: child,
          );
    // On web, suppress the scrollbar inside the rounded content card so the
    // scroll indicator doesn't appear clipped inside the card boundary.
    // This matches the home screen (web) where the scrollable spans the full
    // viewport and the scrollbar appears naturally at the screen edge.
    if (kIsWeb) {
      return ScrollConfiguration(
        behavior: const _NoScrollbarBehavior(),
        child: content,
      );
    }
    return content;
  }

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
    final bottomViewPadding = MediaQuery.viewPaddingOf(context).bottom;
    const useDesktopWebShell = kIsWeb;
    final resolvedTopBorderRadius =
        topBorderRadius ??
        (useDesktopWebShell ? AppTheme.desktopContentCardRadius : 40);
    final resolvedBottomBorderRadius =
        bottomBorderRadius ??
        (useDesktopWebShell ? resolvedTopBorderRadius : 0);
    final contentCardBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(resolvedTopBorderRadius),
      topRight: Radius.circular(resolvedTopBorderRadius),
      bottomLeft: Radius.circular(resolvedBottomBorderRadius),
      bottomRight: Radius.circular(resolvedBottomBorderRadius),
    );
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
                  decoration: _buildContentCardDecoration(
                    isDarkMode: isDarkMode,
                    borderRadius: contentCardBorderRadius,
                    borderColor: webCardBorderColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildContentCardChild(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final mobileBody = SafeArea(
      top: false,
      child: ResponsiveContentWrapper(
        child: Column(
          children: [
            if (headerContent != null) headerContent!,
            Expanded(
              child: Container(
                decoration: _buildContentCardDecoration(
                  isDarkMode: isDarkMode,
                  borderRadius: contentCardBorderRadius,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildContentCardChild(),
              ),
            ),
          ],
        ),
      ),
    );

    if (bottomViewPadding <= 0) return mobileBody;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomViewPadding,
          child: IgnorePointer(
            child: ColoredBox(
              key: _baseScreenLayoutBottomSafeAreaFillKey,
              color: _contentSurfaceColor(isDarkMode: isDarkMode),
            ),
          ),
        ),
        mobileBody,
      ],
    );
  }
}

/// Suppresses the automatic scrollbar added by Flutter web's default
/// [ScrollBehavior]. Used inside [BaseScreenLayout]'s content card so the
/// scrollbar doesn't appear clipped inside the rounded card boundary.
class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
