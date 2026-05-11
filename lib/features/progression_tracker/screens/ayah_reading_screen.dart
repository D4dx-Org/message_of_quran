import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/services/database/arabic_block_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/translation_block_db_helper.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/provider/progression_detail_provider.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/models/progression_ayah_model.dart';

class AyahReadingScreen extends StatefulWidget {
  final int progressionId;
  final int dayId;

  const AyahReadingScreen({
    super.key,
    required this.progressionId,
    required this.dayId,
  });

  @override
  State<AyahReadingScreen> createState() => _AyahReadingScreenState();
}

class _AyahReadingScreenState extends State<AyahReadingScreen> {
  List<ArabicBlockModel> _arabicBlocks = [];
  List<TranslationBlockModel> _translationBlocks = [];
  bool _textLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTextData();
    });
  }

  Future<void> _loadTextData() async {
    final detail = context.read<ProgressionDetailProvider>();
    if (detail.progression == null) return;

    final surahNumber = detail.progression!.surahNumber;
    final results = await Future.wait([
      ArabicBlockDbHelper.getArabicBlocksBySurah(surahNumber),
      TranslationBlockDbHelper.getTranslationBlocksBySurah(surahNumber),
    ]);

    setState(() {
      _arabicBlocks = results[0] as List<ArabicBlockModel>;
      _translationBlocks = results[1] as List<TranslationBlockModel>;
      _textLoaded = true;
    });
  }

  String _getArabicText(int ayahNumber) {
    for (final block in _arabicBlocks) {
      if (block.verseFrom == ayahNumber) {
        return (block.arabicText ?? '').trim();
      }
    }
    return '';
  }

  String _getTranslationText(int ayahNumber) {
    for (final block in _translationBlocks) {
      final from = block.verseFrom ?? 0;
      final to = block.verseTo ?? from;
      if (ayahNumber >= from && ayahNumber <= to) {
        var text = (block.translationText ?? '')
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '')
            .trim();
        if (from == to) {
          return text.replaceFirst(RegExp(r'^[\d,\-]+[\s.]*'), '').trim();
        } else {
          text = text.replaceFirst(RegExp(r'^[\d,\-]+[\s.]*'), '').trim();
          final sentences = text.split('. ');
          final idx = ayahNumber - from;
          if (idx < sentences.length) {
            return sentences[idx].trim();
          }
        }
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardBg = isDark ? const Color(0xFF3C3C3C) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.withValues(alpha: 0.18);

    return BaseScreenLayout(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Progression Tracker',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.appThemePrimary,
      ),
      child: Consumer<ProgressionDetailProvider>(
        builder: (context, detail, _) {
          if (detail.progression == null || detail.currentAyah == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final p = detail.progression!;
          final ayah = detail.currentAyah!;
          final currentDay =
              detail.days.where((d) => d.id == widget.dayId).firstOrNull;
          final ayahs = detail.currentDayAyahs;

          // Find current ayah index in the list
          final currentIndex = ayahs.indexWhere((a) => a.id == ayah.id);
          final hasPrev = currentIndex > 0;
          final hasNext = currentIndex < ayahs.length - 1;

          final arabicText = _textLoaded ? _getArabicText(ayah.ayahNumber) : '';
          final translationText =
              _textLoaded ? _getTranslationText(ayah.ayahNumber) : '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // Surah header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        p.arabicName,
                        style: TextStyle(fontSize: 18, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.arabicName.isNotEmpty ? p.arabicName : p.surahName,
                        style: TextStyle(
                          fontSize: 20,
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (currentDay != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _badge('Day ${currentDay.dayNumber}'),
                            const SizedBox(width: 8),
                            _badge(
                              'Ayah ${currentDay.startAyah} - ${currentDay.endAyah}',
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status tabs
                _buildStatusTabs(context, detail, ayah),
                const SizedBox(height: 16),

                // Ayah display card with navigation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Navigation row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: hasPrev
                                ? () => _navigateToAyah(
                                    detail, ayahs, currentIndex - 1)
                                : null,
                            icon: Icon(
                              Icons.chevron_left,
                              color: hasPrev
                                  ? AppTheme.appIconTheme
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          Text(
                            '${p.surahNumber}:${ayah.ayahNumber}',
                            style: const TextStyle(
                              color: AppTheme.appIconTheme,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          IconButton(
                            onPressed: hasNext
                                ? () => _navigateToAyah(
                                    detail, ayahs, currentIndex + 1)
                                : null,
                            icon: Icon(
                              Icons.chevron_right,
                              color: hasNext
                                  ? AppTheme.appIconTheme
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Arabic text
                      if (!_textLoaded)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        )
                      else ...[
                        Text(
                          arabicText,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 26,
                            color: textColor,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Translation text
                        Text(
                          translationText,
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusTabs(
    BuildContext context,
    ProgressionDetailProvider detail,
    ProgressionAyahModel ayah,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.grey.withValues(alpha: 0.3);

    const statuses = ['pending', 'reading', 'completed'];
    const labels = ['Pending', 'Reading', 'Completed'];

    return Row(
      children: List.generate(3, (i) {
        final isActive = ayah.status == statuses[i];
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              if (ayah.id == null) return;
              await detail.markAyahStatus(ayah.id!, statuses[i]);
              // Update current ayah reference
              final updatedAyahs = detail.currentDayAyahs;
              final updated = updatedAyahs.where((a) => a.id == ayah.id).firstOrNull;
              if (updated != null) {
                detail.setCurrentAyah(updated);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive ? AppTheme.appIconTheme : borderColor,
                  width: isActive ? 2 : 1,
                ),
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(8) : Radius.zero,
                  right: i == 2 ? const Radius.circular(8) : Radius.zero,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[i],
                style: TextStyle(
                  color: isActive ? AppTheme.appIconTheme : textColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _navigateToAyah(
    ProgressionDetailProvider detail,
    List<ProgressionAyahModel> ayahs,
    int index,
  ) {
    if (index < 0 || index >= ayahs.length) return;
    final target = ayahs[index];
    // Only navigate to accessible ayahs
    if (target.status == 'locked') return;
    detail.setCurrentAyah(target);
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.appIconTheme.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.appIconTheme,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
