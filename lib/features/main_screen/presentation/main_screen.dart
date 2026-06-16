import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/features/bookmark_screen/presentation/bookmark_screen.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/home_screen.dart';
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/screens/mushaf_landing_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';
import 'package:the_message_of_the_quran/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    state?._onItemTapped(index);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const double _navIconSize = 24;

  static const List<({String label, IconData? iconData, String? assetPath})>
  _navItems = [
    (label: 'Home', iconData: null, assetPath: 'assets/icons/home-img.png'),
    (
      label: 'Bookmarks',
      iconData: null,
      assetPath: 'assets/icons/bookmark-img.png',
    ),
    (label: '', iconData: null, assetPath: 'assets/icons/mushaf-img-2.png'),
    (
      label: 'Settings',
      iconData: null,
      assetPath: 'assets/icons/settings-img.png',
    ),
  ];

  static const List<Widget> _pages = [
    HomeScreen(),
    BookmarkScreen(),
    MushafLandingScreen(), // index 2
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final isMalayalam = (prefs.getString('app_language') ?? 'en') == 'ml';
      // ignore: use_build_context_synchronously
      final surahProvider = Provider.of<SurahProvider>(context, listen: false);
      await surahProvider.setMalayalam(isMalayalam);
      await surahProvider.getAllSurah();
      if (!mounted) return;

      final pendingRoute = app.pendingNotificationRoute;
      if (pendingRoute == null) {
        return;
      }

      app.pendingNotificationRoute = null;
      final handled = await app.handleNotificationRoute(pendingRoute);
      if (!handled) {
        app.pendingNotificationRoute = pendingRoute;
      }
    });
  }

  void _onItemTapped(int index) {
    // Mushaf (index 2) is temporarily disabled — coming soon.
    if (index == 2) return;
    Provider.of<HomeProvider>(context, listen: false).changeIndex(index);
    final screenNames = ['Home', 'Bookmarks', 'Mushaf', 'Settings'];
    // ignore: deprecated_member_use
    SemanticsService.announce(
      '${screenNames[index.clamp(0, 3)]} screen',
      TextDirection.ltr,
    );
  }

  double _navItemSize(int index) {
    // Render all bottom-nav icons at a single uniform size so no tab (e.g.
    // Settings) appears smaller than the others.
    return _navIconSize;
  }

  Widget _buildNavItemIcon({
    required int index,
    required Color color,
    required double size,
  }) {
    final item = _navItems[index];
    final iconData = item.iconData;
    if (iconData != null) {
      return Icon(iconData, size: size, color: color);
    }

    final assetPath = item.assetPath!;
    if (assetPath.endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Image.asset(assetPath, width: size, height: size, color: color);
  }

  bool _useWebShell(BuildContext context) {
    return kIsWeb;
  }

  Widget _buildWebToolbarActions(BuildContext context, int displayIndex) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 640;
    final selectedPageIndex = switch (displayIndex) {
      0 || 1 || 3 => displayIndex,
      _ => null,
    };
    final toolbar = CommonWebAppBarActions(
      selectedPageIndex: selectedPageIndex,
      onPageSelected: _onItemTapped,
      compact: true,
      showSearch: false,
      showLabels: !isNarrow,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: toolbar,
    );
  }

  Widget _buildWebShell(
    BuildContext context,
    Widget pageBody,
    int displayIndex,
    bool isMalayalam,
  ) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: displayIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onItemTapped(0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CommonAppBar.homeAppBar(
          context,
          showOrnament: false,
          actions: [_buildWebToolbarActions(context, displayIndex)],
        ),
        drawer: const CommonDrawer(),
        body: pageBody,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeProvider>(context);
    final theme = Theme.of(context);
    final bottomViewPadding = MediaQuery.viewPaddingOf(context).bottom;
    final isDarkMode = theme.brightness == Brightness.dark;
    final navBg = isDarkMode
        ? AppTheme.appThemePrimary
        : Colors.white; // AppTheme.appThemeSecondary;
    final navCornerFillColor = isDarkMode
        ? const Color(0xff0c2d52)
        : const Color.fromRGBO(255, 250, 234, 1);
    final inactiveColor = isDarkMode
        ? Colors.grey[400]!
        : const Color(0xFF4A4A4A);
    final displayIndex = controller.currentIndex;
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final tablet = ResponsiveHelper.isTablet(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final navCornerRadius = 28.0 * scale;

    final pageBody = IndexedStack(index: displayIndex, children: _pages);

    if (_useWebShell(context)) {
      return _buildWebShell(context, pageBody, displayIndex, isMalayalam);
    }

    final appBar = displayIndex == 0
        ? CommonAppBar.homeAppBar(context)
        : CommonAppBar.appBar(
            context,
            centerTitle: true,
            isActionsNeeded: displayIndex != 3,
            showLeading: true,
            isMalayalam: false,
            title: [
              'Home',
              'Bookmarks',
              'Mushaf',
              'Settings',
            ][displayIndex.clamp(0, 3)],
          );

    // ── Tablet: NavigationRail on the left ──
    if (tablet) {
      return PopScope(
        canPop: displayIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onItemTapped(0);
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: appBar,
          drawer: const CommonDrawer(),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: displayIndex,
                onDestinationSelected: _onItemTapped,
                backgroundColor: navBg,
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: IconThemeData(
                  color: isDarkMode ? Colors.white : AppTheme.appIconTheme,
                  size: _navIconSize * scale,
                ),
                unselectedIconTheme: IconThemeData(
                  color: inactiveColor,
                  size: _navIconSize * scale,
                ),
                selectedLabelTextStyle: TextStyle(
                  color: isDarkMode ? Colors.white : AppTheme.appIconTheme,
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: inactiveColor,
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w400,
                ),
                destinations: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  return NavigationRailDestination(
                    icon: _buildNavItemIcon(
                      index: index,
                      color: inactiveColor,
                      size: _navItemSize(index) * scale,
                    ),
                    selectedIcon: item.label.isEmpty
                        ? SizedBox.square(
                            dimension: _navItemSize(index) * scale,
                          )
                        : _buildNavItemIcon(
                            index: index,
                            color: AppTheme.appIconTheme,
                            size: _navItemSize(index) * scale,
                          ),
                    label: Text(item.label),
                  );
                }),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: pageBody),
            ],
          ),
        ),
      );
    }

    // ── Phone: BottomNavigationBar ──
    return PopScope(
      canPop: displayIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onItemTapped(0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: appBar,
        drawer: const CommonDrawer(),
        body: pageBody,
        bottomNavigationBar: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NavCornerFillPainter(
                    color: navCornerFillColor,
                    radius: navCornerRadius,
                  ),
                ),
              ),
            ),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(navCornerRadius),
                  topRight: Radius.circular(navCornerRadius),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  6 * scale,
                  0,
                  bottomViewPadding + (6 * scale),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: List.generate(_navItems.length, (index) {
                        // Skip the Mushaf spacer (index 2) — FAB is removed.
                        if (index == 2) return const SizedBox.shrink();
                        final item = _navItems[index];
                        final isSelected = displayIndex == index;

                        final color = isSelected
                            ? (isDarkMode
                                  ? Colors.white
                                  : AppTheme.appIconTheme)
                            : inactiveColor;

                        return Expanded(
                          child: Semantics(
                            button: true,
                            label:
                                '${item.label} tab${isSelected ? ', selected' : ''}',
                            excludeSemantics: true,
                            child: InkWell(
                              onTap: () => _onItemTapped(index),
                              borderRadius: BorderRadius.circular(10 * scale),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6 * scale,
                                  vertical: 4 * scale,
                                ),
                                margin: EdgeInsets.symmetric(
                                  horizontal: 4 * scale,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (item.label.isEmpty)
                                      SizedBox.square(
                                        dimension: _navItemSize(index) * scale,
                                      )
                                    else
                                      _buildNavItemIcon(
                                        index: index,
                                        color: color,
                                        size: _navItemSize(index) * scale,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCornerFillPainter extends CustomPainter {
  const _NavCornerFillPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0 || size.width <= 0 || size.height <= 0) return;

    final wedgeExtent = radius.clamp(0.0, size.width / 2);
    final paint = Paint()..color = color;

    final leftSquare = Path()
      ..addRect(Rect.fromLTWH(0, 0, wedgeExtent, wedgeExtent));
    final leftCircle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(wedgeExtent, wedgeExtent),
          radius: wedgeExtent,
        ),
      );
    final leftWedge = Path.combine(
      PathOperation.difference,
      leftSquare,
      leftCircle,
    );

    final rightSquare = Path()
      ..addRect(
        Rect.fromLTWH(size.width - wedgeExtent, 0, wedgeExtent, wedgeExtent),
      );
    final rightCircle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width - wedgeExtent, wedgeExtent),
          radius: wedgeExtent,
        ),
      );
    final rightWedge = Path.combine(
      PathOperation.difference,
      rightSquare,
      rightCircle,
    );

    canvas.drawPath(leftWedge, paint);
    canvas.drawPath(rightWedge, paint);
  }

  @override
  bool shouldRepaint(_NavCornerFillPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
