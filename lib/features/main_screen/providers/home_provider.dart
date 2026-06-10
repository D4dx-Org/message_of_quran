import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/about_screen/presentation/about_screen.dart';
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

  void changeIndex(int newIndex) {
    if (newIndex < 0 || newIndex > 4) return;
    _currentIndex = newIndex;
    notifyListeners();
  }

  List<Widget> pages = [
    const HomeScreen(),
    const AboutScreen(),
    const BookmarkScreen(),
    const SettingsScreen(),
  ];
}
