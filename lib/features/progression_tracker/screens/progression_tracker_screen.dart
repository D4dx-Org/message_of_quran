import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/provider/progression_tracker_provider.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/screens/add_progression_screen.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/screens/progression_detail_screen.dart';

class ProgressionTrackerScreen extends StatelessWidget {
  const ProgressionTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white70 : Colors.black54;

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
      body: Consumer<ProgressionTrackerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.hasProgressions) {
            return Center(
              child: Text(
                'No Progression is Tracking',
                style: TextStyle(
                  color: subColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: provider.progressions.length,
            itemBuilder: (context, index) {
              final p = provider.progressions[index];
              final completedDays = provider.completedDaysFor(p.id!);
              final completedAyahs = provider.completedAyahsFor(p.id!);
              final percent = p.totalAyahs > 0
                  ? (completedAyahs / p.totalAyahs * 100).round()
                  : 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProgressionDetailScreen(progressionId: p.id!),
                    ),
                  ).then((_) => provider.loadProgressions());
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3C3C3C) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Surah number circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.appIconTheme.withValues(alpha: 0.4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${p.surahNumber}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Surah name + days
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.arabicName.isNotEmpty ? p.arabicName : p.surahName,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Days Completed : $completedDays/${p.totalDays}',
                              style: TextStyle(
                                color: subColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Progress indicator
                      if (percent > 0)
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            color: AppTheme.appIconTheme,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        )
                      else
                        const Icon(
                          Icons.directions_run_rounded,
                          color: AppTheme.appIconTheme,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProgressionScreen()),
          ).then((_) {
            if (!context.mounted) return;
            context.read<ProgressionTrackerProvider>().loadProgressions();
          });
        },
        backgroundColor: AppTheme.appIconTheme,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
