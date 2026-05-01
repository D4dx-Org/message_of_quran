import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/provider/progression_detail_provider.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/screens/ayah_reading_screen.dart';

class ProgressionDayDetailScreen extends StatefulWidget {
  final int progressionId;
  final int dayId;

  const ProgressionDayDetailScreen({
    super.key,
    required this.progressionId,
    required this.dayId,
  });

  @override
  State<ProgressionDayDetailScreen> createState() =>
      _ProgressionDayDetailScreenState();
}

class _ProgressionDayDetailScreenState
    extends State<ProgressionDayDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final detail = context.read<ProgressionDetailProvider>();
      detail.loadProgression(widget.progressionId);
      detail.loadAyahsForDay(widget.dayId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final cardBg = isDark ? const Color(0xFF3C3C3C) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.withValues(alpha: 0.18);

    return Scaffold(
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
      body: Consumer<ProgressionDetailProvider>(
        builder: (context, detail, _) {
          if (detail.isLoading || detail.progression == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final p = detail.progression!;
          // Find current day info
          final currentDay = detail.days.where((d) => d.id == widget.dayId).firstOrNull;
          final ayahs = detail.currentDayAyahs;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        style: TextStyle(
                          fontSize: 18,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.surahName,
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
                            _badge(
                              'Day ${currentDay.dayNumber}',
                              isDark,
                            ),
                            const SizedBox(width: 8),
                            _badge(
                              'Ayah ${currentDay.startAyah} - ${currentDay.endAyah}',
                              isDark,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Find the first pending/locked ayah right after all completed ones
                ...() {
                  int nextPendingIdx = -1;
                  for (int i = 0; i < ayahs.length; i++) {
                    if (ayahs[i].status == 'pending' || ayahs[i].status == 'locked') {
                      final allPriorDone = ayahs.sublist(0, i).every(
                        (a) => a.status == 'completed',
                      );
                      if (allPriorDone) nextPendingIdx = i;
                      break;
                    }
                  }

                  return ayahs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ayah = entry.value;
                    final isReading = ayah.status == 'reading';
                    final isCompleted = ayah.status == 'completed';
                    final isNextPending = index == nextPendingIdx;
                    final isActive = isReading || isNextPending;
                    final canTap = isActive || isCompleted;

                    return GestureDetector(
                      onTap: canTap
                          ? () {
                              detail.setCurrentAyah(ayah);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AyahReadingScreen(
                                    progressionId: widget.progressionId,
                                    dayId: widget.dayId,
                                  ),
                                ),
                              ).then((_) {
                                detail.loadAyahsForDay(widget.dayId);
                                detail.loadProgression(widget.progressionId);
                              });
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Complete the current reading ayah to unlock the next ayah',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            // Ayah number circle
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : isActive
                                        ? AppTheme.appIconTheme.withValues(alpha: 0.15)
                                        : Colors.grey.withValues(alpha: 0.1),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${ayah.ayahNumber}',
                                style: TextStyle(
                                  color: isCompleted
                                      ? Colors.green
                                      : isActive
                                          ? AppTheme.appIconTheme
                                          : subColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ayah ${ayah.ayahNumber}',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${p.arabicName.isNotEmpty ? p.arabicName : p.surahName} • ${p.surahNumber}:${ayah.ayahNumber}',
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        isCompleted
                                            ? Icons.check_circle
                                            : isActive
                                                ? Icons.chrome_reader_mode
                                                : Icons.hourglass_empty,
                                        size: 13,
                                        color: isCompleted
                                            ? Colors.green
                                            : isActive
                                                ? AppTheme.appIconTheme
                                                : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isCompleted
                                            ? 'Completed'
                                            : 'Pending',
                                        style: TextStyle(
                                          color: isCompleted
                                              ? Colors.green
                                              : isActive
                                                  ? AppTheme.appIconTheme
                                                  : Colors.grey,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (canTap)
                              Icon(
                                Icons.chevron_right,
                                color: subColor,
                                size: 20,
                              )
                            else
                              Icon(
                                Icons.lock,
                                color: Colors.grey.withValues(alpha: 0.4),
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  });
                }(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _badge(String text, bool isDark) {
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
