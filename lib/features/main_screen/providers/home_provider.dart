import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/bookmark_screen/presentation/bookmark_screen.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/home_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';

class HomeProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  /// Tracks which sub-tab (Surah = 0, Juz = 1) was last active in HomeScreen.
  /// Stored in-memory so that when SurahScreen rebuilds MainScreen via
  /// _navigateToMainTab the home screen can restore the correct tab.
  int homeSubTabIndex = 0;

  void setHomeSubTabIndex(int index) {
    homeSubTabIndex = index;
  }

  /// Tracks which sub-tab pill is currently hovered (web/desktop pointer).
  int? _hoveredSubTabIndex;

  int? get hoveredSubTabIndex => _hoveredSubTabIndex;

  void setHoveredSubTabIndex(int? index) {
    if (_hoveredSubTabIndex == index) return;
    _hoveredSubTabIndex = index;
    notifyListeners();
  }

  void changeIndex(int newIndex) {
    if (newIndex < 0 || newIndex > 3) return;
    _currentIndex = newIndex;
    notifyListeners();
  }

  List<Widget> pages = [
    const HomeScreen(),
    const BookmarkScreen(),
    const SettingsScreen(),
  ];
}
