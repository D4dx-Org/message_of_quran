import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/data/progression_db_helper.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/models/progression_model.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/models/progression_day_model.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/models/progression_ayah_model.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/services/progression_notification_service.dart';

class ProgressionTrackerProvider extends ChangeNotifier {
  List<ProgressionModel> _progressions = [];
  final Map<int, int> _completedDaysMap = {};
  final Map<int, int> _completedAyahsMap = {};
  bool _isLoading = false;

  List<ProgressionModel> get progressions => _progressions;
  bool get isLoading => _isLoading;
  bool get hasProgressions => _progressions.isNotEmpty;

  /// First active progression (for home card display).
  ProgressionModel? get activeProgression {
    try {
      return _progressions.firstWhere((p) => p.status == 'active');
    } catch (_) {
      return null;
    }
  }

  int completedDaysFor(int progressionId) =>
      _completedDaysMap[progressionId] ?? 0;

  int completedAyahsFor(int progressionId) =>
      _completedAyahsMap[progressionId] ?? 0;

  double progressPercent(int progressionId) {
    final p = _progressions.where((e) => e.id == progressionId).firstOrNull;
    if (p == null) return 0;
    final completed = _completedAyahsMap[progressionId] ?? 0;
    if (p.totalAyahs == 0) return 0;
    return completed / p.totalAyahs;
  }

  ProgressionTrackerProvider() {
    loadProgressions();
  }

  Future<void> loadProgressions() async {
    _isLoading = true;
    notifyListeners();

    _progressions = await ProgressionDbHelper.getAllProgressions();

    // Load completion counts for each progression
    for (final p in _progressions) {
      if (p.id != null) {
        _completedDaysMap[p.id!] =
            await ProgressionDbHelper.getCompletedDayCount(p.id!);
        _completedAyahsMap[p.id!] =
            await ProgressionDbHelper.getCompletedAyahCount(p.id!);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProgression({
    required int surahNumber,
    required String surahName,
    required String arabicName,
    required String place,
    required int totalAyahs,
    required int totalDays,
    required String reminderTime,
    required List<String> reminderDays,
  }) async {
    final ayahsPerDay = (totalAyahs / totalDays).ceil();

    final progression = ProgressionModel(
      surahNumber: surahNumber,
      surahName: surahName,
      arabicName: arabicName,
      place: place,
      totalAyahs: totalAyahs,
      totalDays: totalDays,
      ayahsPerDay: ayahsPerDay,
      reminderTime: reminderTime,
      reminderDays: jsonEncode(reminderDays),
      createdAt: DateTime.now().toIso8601String(),
    );

    final progressionId = await ProgressionDbHelper.insertProgression(
      progression,
    );

    // Generate days and ayahs
    int ayahStart = 1;
    for (int d = 1; d <= totalDays; d++) {
      final ayahEnd = (ayahStart + ayahsPerDay - 1).clamp(1, totalAyahs);
      final isFirstDay = d == 1;

      final day = ProgressionDayModel(
        progressionId: progressionId,
        dayNumber: d,
        startAyah: ayahStart,
        endAyah: ayahEnd,
        status: isFirstDay ? 'reading' : 'pending',
      );

      final dayId = await ProgressionDbHelper.insertDay(day);

      // Generate ayahs for this day
      final ayahs = <ProgressionAyahModel>[];
      for (int a = ayahStart; a <= ayahEnd; a++) {
        final isFirstAyahOfFirstDay = isFirstDay && a == ayahStart;
        ayahs.add(
          ProgressionAyahModel(
            progressionId: progressionId,
            dayId: dayId,
            ayahNumber: a,
            status: isFirstAyahOfFirstDay ? 'reading' : 'pending',
          ),
        );
      }
      await ProgressionDbHelper.insertAyahs(ayahs);

      ayahStart = ayahEnd + 1;
      if (ayahStart > totalAyahs) break;
    }

    // Schedule notifications
    await ProgressionNotificationService.scheduleReminders(
      progressionId: progressionId,
      time: reminderTime,
      days: reminderDays,
      surahName: surahName,
    );

    await loadProgressions();
  }

  Future<void> deleteProgression(int id) async {
    await ProgressionNotificationService.cancelReminders(id);
    await ProgressionDbHelper.deleteProgression(id);
    await loadProgressions();
  }

  Future<void> refreshCounts(int progressionId) async {
    _completedDaysMap[progressionId] =
        await ProgressionDbHelper.getCompletedDayCount(progressionId);
    _completedAyahsMap[progressionId] =
        await ProgressionDbHelper.getCompletedAyahCount(progressionId);
    notifyListeners();
  }
}
