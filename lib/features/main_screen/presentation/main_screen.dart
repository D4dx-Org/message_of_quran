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

  static const List<({String icon, String label})> _navItems = [
    (icon: 'assets/icons/revamp/home_icons.svg', label: 'Home'),
    (icon: 'assets/icons/revamp/bookmarks_page.svg', label: 'Bookmarks'),
    (icon: 'assets/icons/revamp/mushaf_page.svg', label: 'Mushaf'),
    (icon: 'assets/icons/revamp/settings_icon.svg', label: 'Settings'),
    (icon: '', label: 'About'),
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
      await Provider.of<SurahProvider>(context, listen: false).getAllSurah();
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

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final navBg = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final inactiveColor = isDarkMode ? Colors.white70 : const Color(0xFF4A4A4A);
    final displayIndex = controller.currentIndex;
    final tablet = ResponsiveHelper.isTablet(context);
    final scale = ResponsiveHelper.scaleFactor(context);

    final pageBody = IndexedStack(index: displayIndex, children: _pages);

    final appBar = displayIndex == 0
        ? CommonAppBar.homeAppBar(context)
        : CommonAppBar.appBar(
            context,
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
      return Scaffold(
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
                color: AppTheme.appIconTheme,
                size: 26 * scale,
              ),
              unselectedIconTheme: IconThemeData(
                color: inactiveColor,
                size: 24 * scale,
              ),
              selectedLabelTextStyle: TextStyle(
                color: AppTheme.appIconTheme,
                fontSize: 11 * scale,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: inactiveColor,
                fontSize: 11 * scale,
                fontWeight: FontWeight.w400,
              ),
              destinations: _navItems.map((item) {
                return NavigationRailDestination(
                  icon: item.icon.isEmpty
                      ? const Icon(Icons.info_outline_rounded)
                      : SvgPicture.asset(
                          item.icon,
                          width: 24 * scale,
                          height: 24 * scale,
                          colorFilter: ColorFilter.mode(
                            inactiveColor,
                            BlendMode.srcIn,
                          ),
                        ),
                  selectedIcon: item.icon.isEmpty
                      ? const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.appIconTheme,
                        )
                      : SvgPicture.asset(
                          item.icon,
                          width: 24 * scale,
                          height: 24 * scale,
                          colorFilter: const ColorFilter.mode(
                            AppTheme.appIconTheme,
                            BlendMode.srcIn,
                          ),
                        ),
                  label: Text(item.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: pageBody),
          ],
        ),
      );
    }

    // ── Phone: BottomNavigationBar ──
    return Scaffold(
      key: _scaffoldKey,
      appBar: appBar,
      floatingActionButton: FloatingActionButton(onPressed: (){
          _onItemTapped(2);
      },child: SvgPicture.asset(
                                    _navItems[2].icon,
                                    width: 30,
                                    height: 30,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      drawer: const CommonDrawer(),
      body: pageBody,
      bottomNavigationBar: Container(
        clipBehavior: Clip.none,
        // height: 80,
        decoration: BoxDecoration(
          color: navBg,
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
            padding: const EdgeInsets.symmetric(vertical: 6),
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
                            ? AppTheme.appIconTheme
                            : inactiveColor;
                
                    // Mushaf: floating elevated icon, no title
                    // if (isMushaf) {
                    //   return Expanded(
                    //     child: Semantics(
                    //       button: true,
                    //       label: '${item.label} tab${isSelected ? ', selected' : ''}',
                    //       excludeSemantics: true,
                    //       child: GestureDetector(
                    //         onTap: () => _onItemTapped(index),
                    //         child: Transform.translate(
                    //           offset: const Offset(0, -4),
                    //           child: Center(
                    //             child: Container(
                    //               padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    //               decoration: BoxDecoration(
                    //                 color: Colors.white,
                    //                 borderRadius: BorderRadius.circular(10),
                    //                 boxShadow: [
                    //                   BoxShadow(
                    //                     color:Colors.white,
                    //                     blurRadius: 8,
                    //                     offset: const Offset(0, 4),
                    //                   ),
                    //                 ],
                    //               ),
                    //               child: SvgPicture.asset(
                    //                 item.icon,
                    //                 width: 30,
                    //                 height: 30,
                    //                 colorFilter: const ColorFilter.mode(
                    //                   Colors.white,
                    //                   BlendMode.srcIn,
                    //                 ),
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   );
                    // }
                
                    // Other items: no filled bg, just color icon+text
                    return Expanded(
                      child: Semantics(
                        button: true,
                        label: '${item.label} tab${isSelected ? ', selected' : ''}',
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: () => _onItemTapped(index),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.icon.isEmpty)
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 24,
                                    color: color,
                                  )
                                else
                                  SvgPicture.asset(
                                    item.icon,
                                    width: 24,
                                    height: 24,
                                    colorFilter: ColorFilter.mode(
                                      color,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
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
    );
  }
}
