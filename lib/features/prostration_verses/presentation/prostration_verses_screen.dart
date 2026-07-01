import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/data/prostration_verse_model.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/services/prostration_verses_service.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class ProstrationVersesScreen extends StatefulWidget {
  const ProstrationVersesScreen({super.key});

  @override
  State<ProstrationVersesScreen> createState() =>
      _ProstrationVersesScreenState();
}

class _ProstrationVersesScreenState extends State<ProstrationVersesScreen> {
  List<ProstrationVerseModel> _verses = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadVerses();
    });
  }

  Future<void> _loadVerses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final verses = await ProstrationVersesService.loadVerses();
      if (!mounted) return;
      setState(() {
        _verses = verses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ProstrationVersesScreen: load error - $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openSurah(ProstrationVerseModel verse) async {
    final surahProvider = context.read<SurahProvider>();
    await surahProvider.selectSurahByNumber(verse.surahNumber);

    if (!mounted) return;

    final hasSurah = surahProvider.surahList.any(
      (surah) => surah.surahNumber == verse.surahNumber,
    );
    if (!hasSurah) {
      final isMalayalam = context.read<LanguageProvider>().isMalayalam;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMalayalam
                ? 'സൂറത്ത് തുറക്കാനായില്ല.'
                : 'Unable to open this surah.',
          ),
        ),
      );
      return;
    }

    context.push(
      '/surah/${verse.surahNumber}?scrollToAyahId=${verse.ayahNumber}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;

    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: isMalayalam ? 'സുജൂദിന്റെ ആയത്തുകൾ' : 'Prostration Verses',
      ),
      drawer: const CommonDrawer(),
      child: _buildBody(context, isMalayalam),
    );
  }

  Widget _buildBody(BuildContext context, bool isMalayalam) {
    final scale = ResponsiveHelper.scaleFactor(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.appIconTheme),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.error_outline, size: 48, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                isMalayalam
                    ? 'സുജൂദിന്റെ ആയത്തുകൾ ലോഡ് ചെയ്യാനായില്ല.'
                    : 'Could not load the prostration verses.',
                textAlign: TextAlign.center,
                style: AppTextTheme.localizedBody(
                  isMalayalam: isMalayalam,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadVerses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.appIconTheme,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isMalayalam ? 'വീണ്ടും ശ്രമിക്കുക' : 'Retry',
                  style: AppTextTheme.localizedLabel(
                    isMalayalam: isMalayalam,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_verses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isMalayalam
                ? 'സുജൂദിന്റെ ആയത്തുകൾ ലഭ്യമല്ല.'
                : 'No prostration verses available.',
            textAlign: TextAlign.center,
            style: AppTextTheme.localizedBody(
              isMalayalam: isMalayalam,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        24 * scale,
      ),
      itemCount: _verses.length,
      separatorBuilder: (_, _) => SizedBox(height: 12 * scale),
      itemBuilder: (context, index) {
        final verse = _verses[index];
        return _ProstrationVerseTile(
          verse: verse,
          isMalayalam: isMalayalam,
          onTap: () => _openSurah(verse),
        );
      },
    );
  }
}

class _ProstrationVerseTile extends StatelessWidget {
  const _ProstrationVerseTile({
    required this.verse,
    required this.isMalayalam,
    required this.onTap,
  });

  final ProstrationVerseModel verse;
  final bool isMalayalam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = appBarAccentColor(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final badgeColor = isDarkMode
        ? appBarAccentFillColor(context, alpha: 0.22)
        : appBarAccentFillColor(context, alpha: 0.10);
    final title = verse.displaySurahName(isMalayalam: isMalayalam);
    final subtitle = isMalayalam
        ? 'സൂറത്ത് ${verse.surahNumber} - ആയത്ത് ${verse.ayahNumber}'
        : 'Surah ${verse.surahNumber} - Ayah ${verse.ayahNumber}';

    return Semantics(
      button: true,
      label: '$title, $subtitle',
      hint: isMalayalam
          ? 'തുറക്കാൻ ഇരട്ട ടാപ്പ് ചെയ്യുക'
          : 'Double tap to open',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 14 * scale,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42 * scale,
                    height: 42 * scale,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${verse.order}',
                      style: AppTextTheme.popinsDefault(
                        color: accentColor,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 14 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.8,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextTheme.localizedLabel(
                              isMalayalam: isMalayalam,
                              color: accentColor,
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextTheme.localizedBody(
                            isMalayalam: isMalayalam,
                            color: isDarkMode ? Colors.white70 : accentColor,
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: accentColor,
                    size: 26 * scale,
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
