/// Platform-agnostic font store.
///
/// On non-web platforms, fonts are persisted as files in the app's
/// documents directory.  On web, they are stored in IndexedDB so they
/// survive page reloads without requiring re-download.
export 'mushaf_font_store_io.dart'
    if (dart.library.html) 'mushaf_font_store_web.dart';
