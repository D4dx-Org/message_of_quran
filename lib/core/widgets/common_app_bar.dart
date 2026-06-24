import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/app_bar_language_button.dart';
import 'package:the_message_of_the_quran/core/widgets/app_bar_model_sheet.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_svg.dart';
import 'package:the_message_of_the_quran/features/search_screen/presentation/search_screen.dart';

class CommonAppBar {
  CommonAppBar._();

  static Widget _brandLogo(double scale, {VoidCallback? onTap}) {
    final image = Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/Group-logo.png',
        height: 37 * scale,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Quran Asad Malayalam logo',
      ),
    );
    if (onTap == null) return image;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: image),
    );
  }

  static Widget _drawerMenuButton(BuildContext context) {
    final scale = ResponsiveHelper.scaleFactor(context);
    return Semantics(
      button: true,
      label: 'Open navigation menu',
      child: IconButton(
        icon: Image.asset(
          'assets/images/menu-icon-new.png',
          height: AppConstants.appBarIconHeight * scale,
          width: AppConstants.appBarIconWidth * scale,
          fit: BoxFit.contain,
        ),
        onPressed: () => Scaffold.of(context).openDrawer(),
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Primary-themed app bar for the home screen matching the current brand.
  static PreferredSizeWidget homeAppBar(BuildContext ctx) {
    final scale = ResponsiveHelper.scaleFactor(ctx);
    final ornamentTop = -48.0 * scale;
    final ornamentOverflow = 75.0 * scale;
    final ornamentWidth = 137.0 * scale;
    final ornamentHeight = 146.0 * scale;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.appThemePrimary,
      elevation: 0,
      clipBehavior: Clip.none,
      flexibleSpace: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: ornamentTop,
            end: -ornamentOverflow,
            child: Image.asset(
              'assets/images/home_side_image.png',
              width: ornamentWidth,
              height: ornamentHeight,
              fit: BoxFit.contain,
              color: AppTheme.appThemeRawChips,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ],
      ),
      titleSpacing: 4 * scale,
      title: _brandLogo(scale),
      centerTitle: false,
      leading: Builder(
        builder: (context) => _drawerMenuButton(context),
      ),
      actions: [
        const AppBarLanguageButton(),
        const SizedBox(width: 8),
        IconButton(
          icon: const HomeScreenSvg(icon: 'search', color: Colors.white),
          tooltip: 'Search',
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  static PreferredSizeWidget appBar(
    BuildContext ctx, {
    bool isActionsNeeded = true,
    bool showLeading = true,
    bool showBrandLogo = false,
    bool centerTitle = false,
    String? title,
    bool isMalayalam = false,
    Widget? titleWidget,
    VoidCallback? onSurahInfoTap,
    bool showSearch = true,
    bool showJump = true,
    VoidCallback? onSearchTap,
    VoidCallback? onLogoTap,
  }) {
    final scale = ResponsiveHelper.scaleFactor(ctx);
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.appThemePrimary,
      elevation: 0,
      titleSpacing: showBrandLogo
          ? 4 * scale
          : NavigationToolbar.kMiddleSpacing,
      title:
          titleWidget ??
          (showBrandLogo
              ? _brandLogo(scale, onTap: onLogoTap)
              : (title != null
                    ? Text(
                        title,
                        style: AppTextTheme.localizedTitle(
                          isMalayalam: isMalayalam,
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.w600,
                          color: appBarTitleMatchedAccentColor(ctx),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null)),
      centerTitle: showBrandLogo ? false : centerTitle,
      leading: showLeading
          ? Builder(
              builder: (context) => _drawerMenuButton(context),
            )
          : null,
      actions: isActionsNeeded
          ? [
              if (onSurahInfoTap != null)
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/revamp/surah_info_icon.svg',
                    height: AppConstants.appBarIconHeight,
                    width: AppConstants.appBarIconWidth,
                    fit: BoxFit.scaleDown,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  tooltip: 'Surah Info',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: onSurahInfoTap,
                ),
              if (showJump)
                IconButton(
                  icon: const HomeScreenSvg(icon: 'jump', color: Colors.white),
                  tooltip: 'Jump to Surah',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => AppBarModelSheet.modelSheet(ctx),
                ),
              if (showSearch)
                IconButton(
                  icon: const HomeScreenSvg(icon: 'search', color: Colors.white),
                  tooltip: 'Search',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: onSearchTap ??
                      () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          ),
                ),
              const SizedBox(width: 8),
            ]
          : null,
    );
  }
}
