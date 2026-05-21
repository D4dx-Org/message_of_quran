import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/data/prostration_verse_model.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/services/prostration_verses_service.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
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

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahScreen(scrollToAyahId: verse.ayahNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;

    return BaseScreenLayout(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            isMalayalam ? 'സുജൂദിന്റെ ആയത്തുകൾ' : 'Prostration Verses',
            style: AppTextTheme.titleRegular,
          ),
        ),
        centerTitle: false,
      ),
      child: _buildBody(context, isMalayalam),
    );
  }

  Widget _buildBody(BuildContext context, bool isMalayalam) {
    final scale = ResponsiveHelper.scaleFactor(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                style: _bodyStyle(
                  isMalayalam: isMalayalam,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  size: 15,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadVerses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.appIconTheme,
                  foregroundColor: Colors.white,
                ),
                child: Text(isMalayalam ? 'വീണ്ടും ശ്രമിക്കുക' : 'Retry'),
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
            style: _bodyStyle(
              isMalayalam: isMalayalam,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              size: 15,
              weight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF3F4F6),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          20 * scale,
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
      ),
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
    final cardColor = isDarkMode ? theme.cardColor : Colors.white;
    final badgeColor = isDarkMode
        ? appBarAccentFillColor(context, alpha: 0.22)
        : appBarAccentFillColor(context, alpha: 0.10);
    final shadowColor = accentColor.withValues(alpha: isDarkMode ? 0.0 : 0.08);
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
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
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
                      style: GoogleFonts.poppins(
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
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _headlineStyle(
                            isMalayalam: isMalayalam,
                            color: accentColor,
                            size: 15 * scale,
                            weight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _bodyStyle(
                            isMalayalam: isMalayalam,
                            color: isDarkMode ? Colors.white70 : accentColor,
                            size: 12 * scale,
                            weight: FontWeight.w500,
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

TextStyle _headlineStyle({
  required bool isMalayalam,
  required Color? color,
  required double size,
  required FontWeight weight,
}) {
  return isMalayalam
      ? GoogleFonts.notoSerifMalayalam(
          color: color,
          fontSize: size,
          fontWeight: weight,
        )
      : GoogleFonts.poppins(color: color, fontSize: size, fontWeight: weight);
}

TextStyle _bodyStyle({
  required bool isMalayalam,
  required Color? color,
  required double size,
  required FontWeight weight,
}) {
  return isMalayalam
      ? GoogleFonts.notoSerifMalayalam(
          color: color,
          fontSize: size,
          fontWeight: weight,
          height: 1.35,
        )
      : GoogleFonts.poppins(
          color: color,
          fontSize: size,
          fontWeight: weight,
          height: 1.35,
        );
}
