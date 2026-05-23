import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/features/about_screen/presentation/about_screen.dart';
import 'package:the_message_of_the_quran/features/bookmark_screen/presentation/bookmark_screen.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/home_screen.dart';
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/screens/mushaf_landing_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';
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
    (
      label: '',
      iconData: null,
      assetPath: 'assets/icons/mushaf-img-2.png',
    ),
    (
      label: 'Settings',
      iconData: null,
      assetPath: 'assets/icons/settings-img.png',
    ),
    (label: 'About', iconData: null, assetPath: 'assets/icons/about-img.png'),
  ];

  static const List<Widget> _pages = [
    HomeScreen(),
    BookmarkScreen(),
    MushafLandingScreen(), // index 2
    SettingsScreen(),
    AboutScreen(),
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
    Provider.of<HomeProvider>(context, listen: false).changeIndex(index);
    final screenNames = ['Home', 'Bookmarks', 'Mushaf', 'Settings', 'About Us'];
    // ignore: deprecated_member_use
    SemanticsService.announce(
      '${screenNames[index.clamp(0, 4)]} screen',
      TextDirection.ltr,
    );
  }

  double _navItemSize(int index) {
    return switch (index) {
      0 || 3 => _navIconSize - 4,
      1 => _navIconSize - 1,
      _ => _navIconSize,
    };
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
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final navBg = isDarkMode
        ? AppTheme.appThemePrimary
        : Colors.white; // AppTheme.appThemeSecondary;
    final inactiveColor = isDarkMode ? Colors.grey[400]! : const Color(0xFF4A4A4A);
    final displayIndex = controller.currentIndex;
    final tablet = ResponsiveHelper.isTablet(context);
    final scale = ResponsiveHelper.scaleFactor(context);
      final navCornerRadius = 28.0 * scale;

    final pageBody = IndexedStack(index: displayIndex, children: _pages);

    final appBar = displayIndex == 0
        ? CommonAppBar.homeAppBar(context)
        : CommonAppBar.appBar(
            context,
            centerTitle: true,
            isActionsNeeded: displayIndex != 4 && displayIndex != 3,
            showLeading: displayIndex != 4,
            title: const [
              'Home',
              'Bookmarks',
              'Mushaf',
              'Settings',
              'About Us',
            ][displayIndex.clamp(0, 4)],
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _onItemTapped(2);
            },
            child: Image.asset(
              _navItems[2].assetPath!,
              width: _navIconSize,
              height: _navIconSize,
              color: isDarkMode && displayIndex != 2 ? inactiveColor : Colors.white,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
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
        floatingActionButton: Transform.translate(
          offset: Offset(0, 10 * scale),
          child: FloatingActionButton(
            onPressed: () {
              _onItemTapped(2);
            },
            child: Image.asset(
              _navItems[2].assetPath!,
              width: _navIconSize * scale,
              height: _navIconSize * scale,
              color: isDarkMode && displayIndex != 2 ? inactiveColor : Colors.white,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        drawer: const CommonDrawer(),
        body: pageBody,
        bottomNavigationBar: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: navBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(navCornerRadius),
              topRight: Radius.circular(navCornerRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6 * scale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final isSelected = displayIndex == index;
                      final isMushaf = index == 2;

                      final color = isMushaf
                          ? Colors.white
                          : isSelected
                          ? (isDarkMode ? Colors.white : AppTheme.appIconTheme)
                          : inactiveColor;

                      // Other items: active gets a filled container, inactive stays plain
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
                              // decoration:
                              //     ? BoxDecoration(
                              //         color: isDarkMode
                              //             ? Colors.white.withValues(alpha: 0.12)
                              //             : const Color.fromRGBO(
                              //                 255,
                              //                 234,
                              //                 191,
                              //                 1,
                              //               ),
                              //         borderRadius: BorderRadius.circular(10),
                              //       )
                              //     : null,
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
                                  SizedBox(height: 3 * scale),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10 * scale,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
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
        ),
      ),
    );
  }
}
