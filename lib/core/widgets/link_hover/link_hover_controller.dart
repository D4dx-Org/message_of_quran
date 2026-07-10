import 'package:flutter/foundation.dart';

/// Tracks the URL currently under the mouse cursor so [LinkStatusBar] can
/// mimic the browser-style "link preview" strip shown bottom-left on hover.
class LinkHoverController extends ChangeNotifier {
  String? _hoveredUrl;

  String? get hoveredUrl => _hoveredUrl;

  void show(String url) {
    if (_hoveredUrl == url) return;
    _hoveredUrl = url;
    notifyListeners();
  }

  void hide() {
    if (_hoveredUrl == null) return;
    _hoveredUrl = null;
    notifyListeners();
  }
}
