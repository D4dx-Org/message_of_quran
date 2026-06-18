import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/base_screen_layout.dart';
import '../../../core/widgets/responsive_content_wrapper.dart';
import '../provider/mushaf_landing_provider.dart';
import '../services/mushaf_download_manager.dart';
import '../utils/surah_unicode.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mushaf_repository.dart';
import '../widgets/mushaf_download_required_dialog.dart';
import '../widgets/star_number.dart';
import 'mushaf_reader_screen.dart';

// ─── Surah metadata ──────────────────────────────────────────────────────────

class _SurahMeta {
  const _SurahMeta(this.no, this.name, this.meaning, this.ayahs);
  final int no;
  final String name;
  final String meaning;
  final int ayahs;
}

class _QuickAccessItem {
  const _QuickAccessItem({required this.label, this.surahNo, this.ayahNo});

  final String label;
  final int? surahNo;
  final int? ayahNo;
}

const List<int> _revelationOrder = [
  96,
  68,
  73,
  74,
  1,
  111,
  81,
  87,
  92,
  89,
  93,
  94,
  103,
  100,
  108,
  102,
  107,
  109,
  105,
  113,
  114,
  112,
  53,
  80,
  97,
  91,
  85,
  95,
  106,
  101,
  75,
  104,
  77,
  50,
  90,
  86,
  54,
  38,
  7,
  72,
  36,
  25,
  35,
  19,
  20,
  56,
  26,
  27,
  28,
  17,
  10,
  11,
  12,
  15,
  6,
  37,
  31,
  34,
  39,
  40,
  41,
  42,
  43,
  44,
  45,
  46,
  51,
  88,
  18,
  16,
  71,
  14,
  21,
  23,
  32,
  52,
  67,
  69,
  70,
  78,
  79,
  82,
  84,
  30,
  29,
  83,
  2,
  8,
  3,
  33,
  60,
  4,
  99,
  57,
  47,
  13,
  55,
  76,
  65,
  98,
  59,
  24,
  22,
  63,
  58,
  49,
  66,
  64,
  61,
  62,
  48,
  5,
  9,
  110,
];

const List<_SurahMeta> _surahMeta = [
  _SurahMeta(1, 'Al-Fatihah', 'The Opener', 7),
  _SurahMeta(2, 'Al-Baqarah', 'The Cow', 286),
  _SurahMeta(3, "Ali 'Imran", 'Family of Imran', 200),
  _SurahMeta(4, 'An-Nisa', 'The Women', 176),
  _SurahMeta(5, "Al-Ma'idah", 'The Table Spread', 120),
  _SurahMeta(6, "Al-An'am", 'The Cattle', 165),
  _SurahMeta(7, "Al-A'raf", 'The Heights', 206),
  _SurahMeta(8, 'Al-Anfal', 'The Spoils of War', 75),
  _SurahMeta(9, 'At-Tawbah', 'The Repentance', 129),
  _SurahMeta(10, 'Yunus', 'Jonah', 109),
  _SurahMeta(11, 'Hud', 'Hud', 123),
  _SurahMeta(12, 'Yusuf', 'Joseph', 111),
  _SurahMeta(13, "Ar-Ra'd", 'The Thunder', 43),
  _SurahMeta(14, 'Ibrahim', 'Abraham', 52),
  _SurahMeta(15, 'Al-Hijr', 'The Rocky Tract', 99),
  _SurahMeta(16, 'An-Nahl', 'The Bee', 128),
  _SurahMeta(17, 'Al-Isra', 'The Night Journey', 111),
  _SurahMeta(18, 'Al-Kahf', 'The Cave', 110),
  _SurahMeta(19, 'Maryam', 'Mary', 98),
  _SurahMeta(20, 'Ta-Ha', 'Ta-Ha', 135),
  _SurahMeta(21, 'Al-Anbiya', 'The Prophets', 112),
  _SurahMeta(22, 'Al-Hajj', 'The Pilgrimage', 78),
  _SurahMeta(23, "Al-Mu'minun", 'The Believers', 118),
  _SurahMeta(24, 'An-Nur', 'The Light', 64),
  _SurahMeta(25, 'Al-Furqan', 'The Criterion', 77),
  _SurahMeta(26, "Ash-Shu'ara", 'The Poets', 227),
  _SurahMeta(27, 'An-Naml', 'The Ant', 93),
  _SurahMeta(28, 'Al-Qasas', 'The Stories', 88),
  _SurahMeta(29, "Al-'Ankabut", 'The Spider', 69),
  _SurahMeta(30, 'Ar-Rum', 'The Romans', 60),
  _SurahMeta(31, 'Luqman', 'Luqman', 34),
  _SurahMeta(32, 'As-Sajdah', 'The Prostration', 30),
  _SurahMeta(33, 'Al-Ahzab', 'The Combined Forces', 73),
  _SurahMeta(34, 'Saba', 'Sheba', 54),
  _SurahMeta(35, 'Fatir', 'Originator', 45),
  _SurahMeta(36, 'Ya-Sin', 'Ya Sin', 83),
  _SurahMeta(37, 'As-Saffat', 'Those Who Set The Rows', 182),
  _SurahMeta(38, 'Sad', 'The Letter Sad', 88),
  _SurahMeta(39, 'Az-Zumar', 'The Troops', 75),
  _SurahMeta(40, 'Ghafir', 'The Forgiver', 85),
  _SurahMeta(41, 'Fussilat', 'Explained In Detail', 54),
  _SurahMeta(42, 'Ash-Shura', 'The Consultation', 53),
  _SurahMeta(43, 'Az-Zukhruf', 'The Ornaments of Gold', 89),
  _SurahMeta(44, 'Ad-Dukhan', 'The Smoke', 59),
  _SurahMeta(45, 'Al-Jathiyah', 'The Crouching', 37),
  _SurahMeta(46, 'Al-Ahqaf', 'The Wind-Curved Sandhills', 35),
  _SurahMeta(47, 'Muhammad', 'Muhammad', 38),
  _SurahMeta(48, 'Al-Fath', 'The Victory', 29),
  _SurahMeta(49, 'Al-Hujurat', 'The Rooms', 18),
  _SurahMeta(50, 'Qaf', 'The Letter Qaf', 45),
  _SurahMeta(51, 'Adh-Dhariyat', 'The Winnowing Winds', 60),
  _SurahMeta(52, 'At-Tur', 'The Mount', 49),
  _SurahMeta(53, 'An-Najm', 'The Star', 62),
  _SurahMeta(54, 'Al-Qamar', 'The Moon', 55),
  _SurahMeta(55, 'Ar-Rahman', 'The Beneficent', 78),
  _SurahMeta(56, "Al-Waqi'ah", 'The Inevitable', 96),
  _SurahMeta(57, 'Al-Hadid', 'The Iron', 29),
  _SurahMeta(58, 'Al-Mujadila', 'The Pleading Woman', 22),
  _SurahMeta(59, 'Al-Hashr', 'The Exile', 24),
  _SurahMeta(60, 'Al-Mumtahanah', 'She That is to be Examined', 13),
  _SurahMeta(61, 'As-Saff', 'The Ranks', 14),
  _SurahMeta(62, "Al-Jumu'ah", 'The Congregation, Friday', 11),
  _SurahMeta(63, 'Al-Munafiqun', 'The Hypocrites', 11),
  _SurahMeta(64, 'At-Taghabun', 'The Mutual Disillusion', 18),
  _SurahMeta(65, 'At-Talaq', 'The Divorce', 12),
  _SurahMeta(66, 'At-Tahrim', 'The Prohibition', 12),
  _SurahMeta(67, 'Al-Mulk', 'The Sovereignty', 30),
  _SurahMeta(68, 'Al-Qalam', 'The Pen', 52),
  _SurahMeta(69, 'Al-Haqqah', 'The Reality', 52),
  _SurahMeta(70, "Al-Ma'arij", 'The Ascending Stairways', 44),
  _SurahMeta(71, 'Nuh', 'Noah', 28),
  _SurahMeta(72, 'Al-Jinn', 'The Jinn', 28),
  _SurahMeta(73, 'Al-Muzzammil', 'The Enshrouded One', 20),
  _SurahMeta(74, 'Al-Muddaththir', 'The Cloaked One', 56),
  _SurahMeta(75, 'Al-Qiyamah', 'The Resurrection', 40),
  _SurahMeta(76, 'Al-Insan', 'The Man', 31),
  _SurahMeta(77, 'Al-Mursalat', 'The Emissaries', 50),
  _SurahMeta(78, 'An-Naba', 'The Tidings', 40),
  _SurahMeta(79, "An-Nazi'at", 'Those Who Drag Forth', 46),
  _SurahMeta(80, "'Abasa", 'He Frowned', 42),
  _SurahMeta(81, 'At-Takwir', 'The Overthrowing', 29),
  _SurahMeta(82, 'Al-Infitar', 'The Cleaving', 19),
  _SurahMeta(83, 'Al-Mutaffifin', 'The Defrauding', 36),
  _SurahMeta(84, 'Al-Inshiqaq', 'The Sundering', 25),
  _SurahMeta(85, 'Al-Buruj', 'The Mansions of the Stars', 22),
  _SurahMeta(86, 'At-Tariq', 'The Nightcomer', 17),
  _SurahMeta(87, "Al-A'la", 'The Most High', 19),
  _SurahMeta(88, 'Al-Ghashiyah', 'The Overwhelming', 26),
  _SurahMeta(89, 'Al-Fajr', 'The Dawn', 30),
  _SurahMeta(90, 'Al-Balad', 'The City', 20),
  _SurahMeta(91, 'Ash-Shams', 'The Sun', 15),
  _SurahMeta(92, 'Al-Layl', 'The Night', 21),
  _SurahMeta(93, 'Ad-Duha', 'The Morning Hours', 11),
  _SurahMeta(94, 'Ash-Sharh', 'The Relief', 8),
  _SurahMeta(95, 'At-Tin', 'The Fig', 8),
  _SurahMeta(96, "Al-'Alaq", 'The Clot', 19),
  _SurahMeta(97, 'Al-Qadr', 'The Power', 5),
  _SurahMeta(98, 'Al-Bayyinah', 'The Clear Proof', 8),
  _SurahMeta(99, 'Az-Zalzalah', 'The Earthquake', 8),
  _SurahMeta(100, "Al-'Adiyat", 'The Courser', 11),
  _SurahMeta(101, "Al-Qari'ah", 'The Calamity', 11),
  _SurahMeta(102, 'At-Takathur', 'The Rivalry in World Increase', 8),
  _SurahMeta(103, "Al-'Asr", 'The Declining Day', 3),
  _SurahMeta(104, 'Al-Humazah', 'The Traducer', 9),
  _SurahMeta(105, 'Al-Fil', 'The Elephant', 5),
  _SurahMeta(106, 'Quraysh', 'Quraysh', 4),
  _SurahMeta(107, "Al-Ma'un", 'The Small Kindnesses', 7),
  _SurahMeta(108, 'Al-Kawthar', 'The Abundance', 3),
  _SurahMeta(109, 'Al-Kafirun', 'The Disbelievers', 6),
  _SurahMeta(110, 'An-Nasr', 'The Divine Support', 3),
  _SurahMeta(111, 'Al-Masad', 'The Palm Fiber', 5),
  _SurahMeta(112, 'Al-Ikhlas', 'Sincerity', 4),
  _SurahMeta(113, 'Al-Falaq', 'The Daybreak', 5),
  _SurahMeta(114, 'An-Nas', 'Mankind', 6),
];

const List<(String juzName, String startingSurah)> _juzMeta = [
  ('Alif Lam Mim', 'Al-Fatihah 1'),
  ('Sayaqool', 'Al-Baqarah 142'),
  ('Tilkal-Rusul', 'Al-Baqarah 253'),
  ('Lan Tanaloo', "Ali 'Imran 92"),
  ('Wal Mohsanaat', 'An-Nisa 24'),
  ('La Yuhibb-ullah', 'An-Nisa 148'),
  ('Wa Iza Samiu', "Al-Ma'idah 82"),
  ('Wa Law Annana', "Al-An'am 111"),
  ('Qal Al-Malao', "Al-A'raf 88"),
  ('Wa Alamu', 'Al-Anfal 41'),
  ('Yatazeroon', 'At-Tawbah 93'),
  ('Wa Ma Min Dabbah', 'Hud 6'),
  ("Wa Ma Ubarri'u", 'Yusuf 53'),
  ('Rubama', 'Al-Hijr 1'),
  ('Subhanallazi', 'Al-Isra 1'),
  ('Qal Alum', 'Al-Kahf 75'),
  ('Iqtaraba', 'Al-Anbiya 1'),
  ('Qad Aflaha', "Al-Mu'minun 1"),
  ('Wa Qalallazina', 'Al-Furqan 21'),
  ('Amman Khalaq', 'An-Naml 59'),
  ('Utlu Ma Uhiya', "Al-'Ankabut 45"),
  ('Wa Man Yaqnut', 'Al-Ahzab 31'),
  ('Wa Mali', 'Ya-Sin 27'),
  ('Fa Man Azlamu', 'Az-Zumar 32'),
  ('Ilahe Yuruddu', 'Fussilat 47'),
  ('Ha-Mim', 'Al-Ahqaf 1'),
  ('Qala Fa Ma Khatbukum', 'Adh-Dhariyat 31'),
  ('Qad Sami Allah', 'Al-Mujadila 1'),
  ('Tabarakallazi', 'Al-Mulk 1'),
  ('Amma', 'An-Naba 1'),
];

const List<_QuickAccessItem> _quickAccessItems = [
  _QuickAccessItem(label: 'Ayatul Kursi', surahNo: 2, ayahNo: 255),
  _QuickAccessItem(label: 'Surah Yaseen', surahNo: 36),
  _QuickAccessItem(label: 'Surah Al-Mulk', surahNo: 67),
  _QuickAccessItem(label: 'Ar-Rahman', surahNo: 55),
  _QuickAccessItem(label: 'Al-Waqi\'ah', surahNo: 56),
  _QuickAccessItem(label: 'Al-Kahf', surahNo: 18),
];

// ─── Colors ───────────────────────────────────────────────────────────────
const _kPrimaryColor = AppTheme.appIconTheme;
const _kSecondaryDark = AppTheme.appIconTheme;
const _kWhite = Color(0xffFFFFFF);
const _kBlack = Color(0xff000000);
const _kWhite70 = Color(0xB3FFFFFF);
const _kBlack54 = Color(0x8A000000);
const _kGrey3C = Color(0xff163d6e);
const _kMaddina = 'assets/icons/revamp/madeena_icon.svg';
const _kMakkah = 'assets/icons/revamp/makkah_icon.svg';

// ─── Screen ───────────────────────────────────────────────────────────────

class MushafLandingScreen extends StatefulWidget {
  const MushafLandingScreen({
    super.key,
    this.embedded = false,
    this.onSurahSelected,
  });

  final bool embedded;
  final ValueChanged<int>? onSurahSelected;

  /// Returns the first Mus'haf page number for the given [suraNo].
  /// Used by the search delegate in MainScreen without requiring a full provider.
  static Future<int> fetchFirstPageForSurah(int suraNo) =>
      MushafRepository().getFirstPageForSurah(suraNo);

  @override
  State<MushafLandingScreen> createState() => _MushafLandingScreenState();
}

class _MushafLandingScreenState extends State<MushafLandingScreen>
    with SingleTickerProviderStateMixin {
  static const double _embeddedBottomNavOffset = kBottomNavigationBarHeight;
  static const Set<int> _madinanSurahs = <int>{
    2,
    3,
    4,
    5,
    8,
    9,
    22,
    24,
    33,
    47,
    48,
    49,
    57,
    58,
    59,
    60,
    61,
    62,
    63,
    64,
    65,
    66,
    76,
    98,
    99,
    110,
  };

  late final TabController _tabController;
  late final MushafLandingProvider _p;
  final MushafDownloadManager _downloadManager = MushafDownloadManager.instance;
  static const Duration _downloadBannerDuration = Duration(seconds: 3);
  Timer? _downloadBannerTimer;
  String? _downloadBannerMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _p = MushafLandingProvider();
    _downloadManager.addListener(_onDownloadStateChanged);
  }

  @override
  void dispose() {
    _downloadBannerTimer?.cancel();
    _downloadManager.removeListener(_onDownloadStateChanged);
    _tabController.dispose();
    _p.dispose();
    super.dispose();
  }

  void _onDownloadStateChanged() {
    if (_downloadManager.isDone && mounted) {
      _hideDownloadBanner();
      _p.setFontsInstalled();
      return;
    }

    if (!_downloadManager.isDownloading) {
      _hideDownloadBanner();
    }
  }

  void _showDownloadBanner(String message) {
    if (!mounted) return;

    _downloadBannerTimer?.cancel();
    setState(() {
      _downloadBannerMessage = message;
    });

    _downloadBannerTimer = Timer(_downloadBannerDuration, () {
      if (!mounted) return;
      setState(() {
        _downloadBannerMessage = null;
      });
    });
  }

  void _hideDownloadBanner() {
    _downloadBannerTimer?.cancel();
    if (!mounted || _downloadBannerMessage == null) return;

    setState(() {
      _downloadBannerMessage = null;
    });
  }

  bool _useDesktopWebLayout(BuildContext context) {
    return kIsWeb;
  }

  Widget _buildDownloadBanner(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isVisible = _downloadBannerMessage != null;
    final maxWidth = ResponsiveHelper.bottomSheetMaxWidth(context);
    final horizontalPadding = ResponsiveHelper.isTablet(context)
        ? ResponsiveHelper.horizontalPadding(context)
        : 0.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: isVisible ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            opacity: isVisible ? 1 : 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth ?? double.infinity,
                ),
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: _downloadBannerMessage ?? '',
                  child: Material(
                    color: isDarkMode ? theme.cardColor : Colors.white,
                    elevation: 10,
                    shadowColor: Colors.black.withValues(alpha: 0.14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      child: Text(
                        _downloadBannerMessage ?? '',
                        style: AppTextTheme.popinsDefault(
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF22304A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSurah(BuildContext context, int suraNo) async {
    if (widget.onSurahSelected != null) {
      widget.onSurahSelected!(suraNo);
      return;
    }
    final page = await _p.getFirstPageForSurah(suraNo);
    if (!context.mounted) return;
    if (!_p.fontsInstalled && page > MushafLandingProvider.previewPageLimit) {
      _handleUndownloadedPage(context);
      return;
    }
    _p.saveMushafSurahSelection(suraNo);
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MushafReaderScreen(initialPage: page),
          ),
        )
        .then((_) => _p.refreshAfterReader());
  }

  Future<void> _openRevelationSurah(BuildContext context, int suraNo) async {
    final page = await _p.getFirstPageForSurah(suraNo);
    if (!context.mounted) return;
    if (!_p.fontsInstalled && page > MushafLandingProvider.previewPageLimit) {
      _handleUndownloadedPage(context);
      return;
    }
    _p.saveMushafRevelationSelection(suraNo);
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MushafReaderScreen(initialPage: page),
          ),
        )
        .then((_) => _p.refreshAfterReader());
  }

  void _openJuz(BuildContext context, int juzNo, int firstPage) {
    if (!_p.fontsInstalled &&
        firstPage > MushafLandingProvider.previewPageLimit) {
      _handleUndownloadedPage(context);
      return;
    }
    _p.saveMushafJuzSelection(juzNo);
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MushafReaderScreen(initialPage: firstPage),
          ),
        )
        .then((_) => _p.refreshAfterReader());
  }

  Future<void> _openSurahAyah(
    BuildContext context, {
    required int suraNo,
    required int ayaNo,
  }) async {
    final page = await _p.getPageForSurahAyah(suraNo, ayaNo);
    if (!context.mounted) return;
    _openPage(context, page);
  }

  void _openPage(BuildContext context, int page) {
    if (!_p.fontsInstalled && page > MushafLandingProvider.previewPageLimit) {
      _handleUndownloadedPage(context);
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MushafReaderScreen(initialPage: page),
          ),
        )
        .then((_) => _p.refreshAfterReader());
  }

  void _handleUndownloadedPage(BuildContext context) {
    if (_downloadManager.isDownloading) {
      final percent = (_downloadManager.progress * 100).toStringAsFixed(0);
      _showDownloadBanner('Download in progress — $percent% complete');
      return;
    }
    _showDownloadDialog(context);
  }

  void _showDownloadDialog(BuildContext context) {
    final maxW = ResponsiveHelper.bottomSheetMaxWidth(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW ?? double.infinity),
          child: MushafDownloadRequiredDialog(
            onCancel: () => Navigator.of(ctx).pop(),
            onDownload: () {
              Navigator.of(ctx).pop();
              _downloadManager.startDownload();
              _showDownloadBanner(
                'Mushaf download started. You can continue using the app.',
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _p,
      child: Consumer<MushafLandingProvider>(
        builder: (context, p, _) {
          if (widget.embedded) return _buildScreenBody(context);
          return _buildScaffold(context);
        },
      ),
    );
  }

  Widget _buildScreenBody(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBody(context),
        _buildDownloadBanner(context),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_useDesktopWebLayout(context)) {
      return _buildDesktopBody(context, isDarkMode);
    }

    if (isLandscape) {
      return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _buildRecentlyReadSection(context, isDarkMode, isLandscape),
          ),
          SliverToBoxAdapter(
            child: _buildTabBar(context, isDarkMode, isLandscape),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSurahTab(context, isDarkMode),
            _buildJuzTab(context, isDarkMode),
            _buildRevelationTab(context, isDarkMode),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecentlyReadSection(context, isDarkMode, isLandscape),
        _buildTabBar(context, isDarkMode, isLandscape),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSurahTab(context, isDarkMode),
              _buildJuzTab(context, isDarkMode),
              _buildRevelationTab(context, isDarkMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopBody(BuildContext context, bool isDarkMode) {
    final useTwoColumns = MediaQuery.sizeOf(context).width >= 980;
    final panelColor = isDarkMode ? _kGrey3C : Colors.white;
    final panelBorder = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final mutedColor = isDarkMode ? Colors.white70 : Colors.black54;

    final overviewPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRecentlyReadSection(context, isDarkMode, useTwoColumns),
        const SizedBox(height: 18),
        DecoratedBox(
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: panelBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mushaf Reading',
                  style: AppTextTheme.popinsDefault(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : _kGrey3C,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Open the last page you reached, browse by surah or juz, and keep the reader controls within easy reach on desktop.',
                  style: AppTextTheme.popinsDefault(
                    fontSize: 13,
                    height: 1.5,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPage(context, _p.lastRead?.page ?? 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kSecondaryDark,
                      foregroundColor: _kWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(
                      _p.lastRead == null
                          ? 'Open Mushaf'
                          : 'Continue on page ${_p.lastRead?.page ?? 1}',
                      style: AppTextTheme.popinsDefault(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kWhite,
                      ),
                    ),
                  ),
                ),
                if (!_p.fontsInstalled) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDownloadDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDarkMode ? Colors.white : _kSecondaryDark,
                        side: BorderSide(
                          color: (isDarkMode ? Colors.white : _kSecondaryDark).withValues(alpha: 0.16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: Text(
                        'Download full Mushaf',
                        style: AppTextTheme.popinsDefault(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : _kSecondaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );

    final browserPanel = DecoratedBox(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: panelBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildTabBar(context, isDarkMode, useTwoColumns),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSurahTab(context, isDarkMode),
                _buildJuzTab(context, isDarkMode),
                _buildRevelationTab(context, isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: useTwoColumns
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 320,
                  child: SingleChildScrollView(child: overviewPanel),
                ),
                const SizedBox(width: 24),
                Expanded(child: browserPanel),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                overviewPanel,
                const SizedBox(height: 24),
                Expanded(child: browserPanel),
              ],
            ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return BaseScreenLayout(
      contentCardBoxShadows: const [],
      child: _buildScreenBody(context),
    );
  }

  // ─── Recently Read ────────────────────────────────────────────────────────

  Widget _buildRecentlyReadSection(
    BuildContext context,
    bool isDarkMode,
    bool isLandscape,
  ) {
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subColor = isDarkMode ? Colors.white60 : Colors.black54;
    final cardBg = isDarkMode ? _kGrey3C : Colors.white;

    final suraNo = _p.lastRead?.suraNo ?? 1;
    final ayaNo = _p.lastRead?.ayaNo ?? 1;
    final meta = suraNo >= 1 && suraNo <= 114
        ? _surahMeta[suraNo - 1]
        : _surahMeta[0];
    final arabicGlyph = SurahUnicodeData.getSurahNameUnicode(suraNo);

    final hPad = ResponsiveHelper.horizontalPadding(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickAccessWrap(context, isDarkMode, isLandscape),
          SizedBox(height: isLandscape ? 6 : 8),
          Text(
            'Recently Read',
            style: TextStyle(
              color: textColor,
              fontSize: isLandscape ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isLandscape ? 6 : 8),
          GestureDetector(
            onTap: () => _openPage(context, _p.lastRead?.page ?? 1),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 8 : 12,
                vertical: isLandscape ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.grey.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    arabicGlyph,
                    style: TextStyle(
                      fontSize: isLandscape ? 18 : 22,
                      fontFamily: 'sura_names',
                      color: textColor,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(width: isLandscape ? 8 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Surah ${meta.name}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: isLandscape ? 13 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${meta.meaning} • Ayah $ayaNo',
                          style: TextStyle(
                            color: subColor,
                            fontSize: isLandscape ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: subColor,
                    size: isLandscape ? 18 : 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessWrap(
    BuildContext context,
    bool isDarkMode,
    bool isLandscape,
  ) {
    final spacing = isLandscape ? 6.0 : 8.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_quickAccessItems.length, (index) {
          final item = _quickAccessItems[index];

          return Padding(
            padding: EdgeInsets.only(
              right: index == _quickAccessItems.length - 1 ? 0 : spacing,
            ),
            child: _buildQuickAccessChip(
              context,
              item,
              isDarkMode,
              isLandscape,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickAccessChip(
    BuildContext context,
    _QuickAccessItem item,
    bool isDarkMode,
    bool isLandscape,
  ) {
    final borderColor = AppTheme.appIconTheme.withValues(alpha: 0.75);
    final chipBg = isDarkMode
        ? AppTheme.appIconTheme.withValues(alpha: 0.12)
        : Colors.white;
    final labelColor = isDarkMode ? Colors.white : Colors.black87;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (item.ayahNo != null && item.surahNo != null) {
            _openSurahAyah(context, suraNo: item.surahNo!, ayaNo: item.ayahNo!);
            return;
          }

          if (item.surahNo != null) {
            _openSurah(context, item.surahNo!);
          }
        },
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 10 : 12,
            vertical: isLandscape ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Text(
            item.label,
            style: TextStyle(
              color: labelColor,
              fontSize: isLandscape ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar(BuildContext context, bool isDarkMode, bool isLandscape) {
    final greyLineColor = isDarkMode
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    final hPad = ResponsiveHelper.horizontalPadding(context);
    return Padding(
      padding: EdgeInsets.only(
        top: isLandscape ? 8 : 20,
        left: hPad,
        right: hPad,
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(height: 2, color: greyLineColor),
          ),
          TabBar(
            controller: _tabController,
            indicator: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _kSecondaryDark, width: 2.0),
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: isDarkMode ? Colors.white : _kSecondaryDark,
            unselectedLabelColor: isDarkMode
                ? Colors.grey[400]
                : Colors.grey[600],
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            tabs: [
              Tab(
                height: 30,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Surah',
                    style: AppTextTheme.popinsDefault(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Tab(
                height: 30,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    "Juz'e",
                    style: AppTextTheme.popinsDefault(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Tab(
                height: 30,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Revelation',
                    style: AppTextTheme.popinsDefault(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Surah Tab ────────────────────────────────────────────────────────────

  Widget _buildSurahTab(BuildContext context, bool isDarkMode) {
    final surahs = _p.sortAscending ? _surahMeta : _surahMeta.reversed.toList();
    final sortLabelColor = isDarkMode ? Colors.white54 : Colors.black45;
    final sortStatusColor = isDarkMode ? sortLabelColor : _kPrimaryColor;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.horizontalPadding(context),
            vertical: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _p.toggleSort,
                child: Row(
                  children: [
                    Text(
                      'SORT BY: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: sortLabelColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _p.sortAscending ? 'ASCENDING' : 'DESCENDING',
                      style: TextStyle(
                        fontSize: 11,
                        color: sortStatusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _p.sortAscending
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: sortStatusColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ResponsiveContentWrapper(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.horizontalPadding(context),
                0,
                ResponsiveHelper.horizontalPadding(context),
                0,
              ),
              itemCount: surahs.length,
              itemBuilder: (context, i) =>
                  _buildSurahCard(context, surahs[i], isDarkMode),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Juz Tab ──────────────────────────────────────────────────────────────

  Widget _buildJuzTab(BuildContext context, bool isDarkMode) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + _embeddedBottomNavOffset + 16;

    final hPad = ResponsiveHelper.horizontalPadding(context);
    return ResponsiveContentWrapper(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPadding),
        itemCount: 30,
        itemBuilder: (context, i) {
          final juzNo = i + 1;
          final meta = _juzMeta[i];
          final firstPage = _p.juzPages.length > i
              ? _p.juzPages[i].firstPage
              : 1;
          return _buildJuzCard(
            context,
            juzNo,
            meta.$1,
            meta.$2,
            firstPage,
            isDarkMode,
          );
        },
      ),
    );
  }

  // ─── Revelation Tab ───────────────────────────────────────────────────────

  Widget _buildRevelationTab(BuildContext context, bool isDarkMode) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + _embeddedBottomNavOffset + 16;
    final surahs = <_SurahMeta>[];
    for (final suraNo in _revelationOrder) {
      if (suraNo >= 1 && suraNo <= 114) surahs.add(_surahMeta[suraNo - 1]);
    }

    final hPad = ResponsiveHelper.horizontalPadding(context);
    return ResponsiveContentWrapper(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPadding),
        itemCount: surahs.length,
        itemBuilder: (context, i) => _buildSurahCard(
          context,
          surahs[i],
          isDarkMode,
          revelationIndex: i + 1,
        ),
      ),
    );
  }

  // ─── Card Widgets ─────────────────────────────────────────────────────────

  Widget _buildSurahCard(
    BuildContext context,
    _SurahMeta meta,
    bool isDarkMode, {
    int? revelationIndex,
  }) {
    final textColor = isDarkMode ? _kWhite : _kBlack;
    final subColor = isDarkMode ? _kWhite70 : _kBlack54;
    final cardBg = isDarkMode ? _kGrey3C : Colors.white;
    final metaIcon = _madinanSurahs.contains(meta.no) ? _kMaddina : _kMakkah;
    final arabicGlyph = SurahUnicodeData.getSurahNameUnicode(meta.no);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => revelationIndex != null
            ? _openRevelationSurah(context, meta.no)
            : _openSurah(context, meta.no),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                StarNumber(
                  number: revelationIndex ?? meta.no,
                  isHighlighted: revelationIndex != null
                      ? _p.lastMushafRevelationSelection == meta.no
                      : _p.lastMushafSurahSelection == meta.no,
                  textColor: isDarkMode ? _kWhite : _kBlack,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.name,
                        style: AppTextTheme.popinsDefault(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SvgPicture.asset(
                            metaIcon,
                            height: 12,
                            width: 12,
                            colorFilter: ColorFilter.mode(
                              isDarkMode
                                  ? const Color(0xB3FFFFFF)
                                  : AppTheme.appIconTheme,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.circle, size: 6, color: subColor),
                          const SizedBox(width: 4),
                          Text(
                            '${meta.ayahs}',
                            style: AppTextTheme.popinsDefault(
                              fontSize: 10,
                              color: subColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meta.meaning,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextTheme.popinsDefault(
                                fontSize: 10,
                                color: subColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  arabicGlyph,
                  style: TextStyle(
                    color: isDarkMode
                        ? _kWhite70.withValues(alpha: 0.87)
                        : _kBlack,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'sura_names',
                    fontSize: 30,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJuzCard(
    BuildContext context,
    int juzNo,
    String juzName,
    String startsSurah,
    int firstPage,
    bool isDarkMode,
  ) {
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subColor = isDarkMode ? Colors.white54 : Colors.black54;
    final cardBg = isDarkMode ? _kGrey3C : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _openJuz(context, juzNo, firstPage),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.grey.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              StarNumber(
                number: juzNo,
                outlineOnly: true,
                isHighlighted: _p.lastMushafJuzSelection == juzNo,
                size: 42,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Juz $juzNo',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      juzName,
                      style: TextStyle(color: subColor, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
               const SizedBox(width: 12),
               Text(
                 startsSurah,
                 style: TextStyle(
                   color: subColor,
                   fontSize: 11,
                 ),
                 textAlign: TextAlign.end,
               ),
             ],
           ),
         ),
       ),
     );
   }
}
