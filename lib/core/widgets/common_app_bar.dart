import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/app_bar_language_button.dart';
import 'package:the_message_of_the_quran/core/widgets/app_bar_model_sheet.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_svg.dart';
import 'package:the_message_of_the_quran/features/search_screen/presentation/search_screen.dart';

class CommonAppBar {
  CommonAppBar._();

  static Widget _brandLogo(double scale) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/Group-logo.png',
        height: 40 * scale,
        fit: BoxFit.contain,
        semanticLabel: 'The Message of the Quran logo',
      ),
    );
  }

  /// Brown-themed app bar for the home screen matching the screenshot design.
  static PreferredSizeWidget homeAppBar(BuildContext ctx) {
    final scale = ResponsiveHelper.scaleFactor(ctx);
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.appThemePrimary,
      elevation: 0,
      clipBehavior: Clip.none,
      flexibleSpace: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -48,
            left: 298,
            child: Image.asset(
              'assets/images/home_side_image.png',
              width: 137,
              height: 146,
              fit: BoxFit.contain,
              color: const Color.fromRGBO(124, 58, 40, 1),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ],
      ),
      titleSpacing: 4 * scale,
      title: _brandLogo(scale),
      centerTitle: false,
      leading: Builder(
        builder: (context) => Semantics(
          button: true,
          label: 'Open navigation menu',
          child: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      actions: [
        const AppBarLanguageButton(),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
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
    Widget? titleWidget,
    VoidCallback? onSurahInfoTap,
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
              ? _brandLogo(scale)
              : (title != null
                    ? Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromRGBO(255, 232, 187, 1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null)),
      centerTitle: showBrandLogo ? false : centerTitle,
      leading: showLeading
          ? Builder(
              builder: (context) => Semantics(
                button: true,
                label: 'Open navigation menu',
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  padding: EdgeInsets.zero,
                ),
              ),
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
              IconButton(
                icon: const HomeScreenSvg(icon: 'jump', color: Colors.white),
                tooltip: 'Jump to Surah',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => AppBarModelSheet.modelSheet(ctx),
              ),
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
            ]
          : null,
    );
  }
}
