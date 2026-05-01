import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/provider/progression_detail_provider.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/provider/progression_tracker_provider.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/screens/progression_day_detail_screen.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/services/progression_notification_service.dart';

class ProgressionDetailScreen extends StatefulWidget {
  final int progressionId;
  const ProgressionDetailScreen({super.key, required this.progressionId});

  @override
  State<ProgressionDetailScreen> createState() =>
      _ProgressionDetailScreenState();
}

class _ProgressionDetailScreenState extends State<ProgressionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressionDetailProvider>().loadProgression(
        widget.progressionId,
      );
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Progression'),
        content: const Text(
          'Are you sure you want to delete this progression? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ProgressionTrackerProvider>().deleteProgression(
        widget.progressionId,
      );
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _editReminder() async {
    final detail = context.read<ProgressionDetailProvider>();
    final progression = detail.progression;
    if (progression == null) return;

    final currentTime = ProgressionNotificationService.parseStoredTime(
      progression.reminderTime,
    );
    final currentDays = detail.reminderDaysList;

    TimeOfDay selectedTime = currentTime;
    List<String> selectedDays = List.from(currentDays);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black;
            final cardBg =
                isDark ? const Color(0xFF3C3C3C) : Colors.white;
            final borderColor = isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.18);

            return AlertDialog(
              title: const Text('Edit Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: textColor.withValues(alpha: 0.5)),
                          const SizedBox(width: 8),
                          Text(selectedTime.format(ctx)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Days', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ].map((day) {
                      final sel = selectedDays.contains(day);
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            if (sel) {
                              selectedDays.remove(day);
                            } else {
                              selectedDays.add(day);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                sel ? AppTheme.appIconTheme : cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.appIconTheme
                                  : borderColor,
                            ),
                          ),
                          child: Text(
                            day,
                            style: TextStyle(
                              color: sel ? Colors.white : textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: AppTheme.appIconTheme),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      await detail.updateReminder(
        time: ProgressionNotificationService.parseDisplayTime(selectedTime),
        days: selectedDays,
      );
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Consumer<ProgressionDetailProvider>(
        builder: (context, detail, _) {
          if (detail.isLoading || detail.progression == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final p = detail.progression!;
          final percent = detail.progressPercentInt;
          final reminderDays = detail.reminderDaysList;
          final reminderSchedule = ProgressionNotificationService.formatSchedule(
            p.reminderTime,
            reminderDays,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Header card: surah name + percentage
                Container(
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.arabicName.isNotEmpty ? p.arabicName : p.surahName,
                              style: const TextStyle(
                                color: AppTheme.appIconTheme,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${detail.completedDayCount}/ ${p.totalDays}',
                              style: TextStyle(
                                color: subColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$percent %',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          ),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Reminder card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.appIconTheme.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppTheme.appIconTheme,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily reminder',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reminderSchedule,
                              style: TextStyle(
                                color: subColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _editReminder,
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: AppTheme.appIconTheme,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Day list
                ...detail.days.map((day) {
                  final isReading = day.status == 'reading';
                  final isCompleted = day.status == 'completed';

                  return GestureDetector(
                    onTap: (isReading || isCompleted)
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProgressionDayDetailScreen(
                                  progressionId: widget.progressionId,
                                  dayId: day.id!,
                                ),
                              ),
                            ).then((_) {
                              detail.loadProgression(widget.progressionId);
                            });
                          }
                        : null,
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Day number circle
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? AppTheme.appIconTheme.withValues(alpha: 0.15)
                                  : isReading
                                      ? AppTheme.appIconTheme.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.dayNumber}',
                              style: TextStyle(
                                color: isCompleted || isReading
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
                                Row(
                                  children: [
                                    Text(
                                      'Day ${day.dayNumber}',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isReading) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.menu_book_rounded,
                                        size: 14,
                                        color: AppTheme.appIconTheme,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ayah ${day.startAyah} - ${day.endAyah}',
                                  style: TextStyle(
                                    color: subColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCompleted
                                      ? 'Completed'
                                      : isReading
                                          ? 'Reading'
                                          : 'Pending',
                                  style: TextStyle(
                                    color: isCompleted
                                        ? Colors.green
                                        : isReading
                                            ? AppTheme.appIconTheme
                                            : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (day.status == 'pending')
                            Icon(
                              Icons.radio_button_unchecked,
                              color: Colors.grey.withValues(alpha: 0.4),
                              size: 20,
                            )
                          else
                            Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : Icons.adjust,
                              color: isCompleted
                                  ? Colors.green
                                  : AppTheme.appIconTheme,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
