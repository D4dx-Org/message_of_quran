import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/about_screen/presentation/about_screen.dart';
import 'package:the_message_of_the_quran/features/bookmark_screen/presentation/bookmark_screen.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/home_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';

class HomeProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  /// Whether the app bar, the quick-ayah chips and the bottom navigation are
  /// showing. The home list hides them as the reader scrolls down so the list
  /// has the screen to itself, and brings them back on the first scroll up --
  /// on a phone held sideways the chrome is most of the height, so this is the
  /// difference between two surahs on screen and eight.
  bool _chromeVisible = true;

  bool get chromeVisible => _chromeVisible;

  void setChromeVisible(bool visible) {
    if (_chromeVisible == visible) return;
    _chromeVisible = visible;
    notifyListeners();
  }

  void changeIndex(int newIndex) {
    // Whatever the last screen left hidden, a tab arrives with its chrome.
    _chromeVisible = true;
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
