import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/data/progression_db_helper.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/models/progression_model.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/models/progression_day_model.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/models/progression_ayah_model.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/services/progression_notification_service.dart';

class ProgressionDetailProvider extends ChangeNotifier {
  ProgressionModel? _progression;
  List<ProgressionDayModel> _days = [];
  List<ProgressionAyahModel> _currentDayAyahs = [];
  ProgressionAyahModel? _currentAyah;
  int _completedAyahCount = 0;
  int _completedDayCount = 0;
  bool _isLoading = false;

  ProgressionModel? get progression => _progression;
  List<ProgressionDayModel> get days => _days;
  List<ProgressionAyahModel> get currentDayAyahs => _currentDayAyahs;
  ProgressionAyahModel? get currentAyah => _currentAyah;
  int get completedAyahCount => _completedAyahCount;
  int get completedDayCount => _completedDayCount;
  bool get isLoading => _isLoading;

  double get progressPercent {
    if (_progression == null || _progression!.totalAyahs == 0) return 0;
    return _completedAyahCount / _progression!.totalAyahs;
  }

  int get progressPercentInt => (progressPercent * 100).round();

  List<String> get reminderDaysList {
    if (_progression == null) return [];
    try {
      return List<String>.from(jsonDecode(_progression!.reminderDays));
    } catch (_) {
      return [];
    }
  }

  Future<void> loadProgression(int id) async {
    _isLoading = true;
    notifyListeners();

    _progression = await ProgressionDbHelper.getProgressionById(id);
    if (_progression != null) {
      _days = await ProgressionDbHelper.getDaysForProgression(id);
      _completedAyahCount = await ProgressionDbHelper.getCompletedAyahCount(id);
      _completedDayCount = await ProgressionDbHelper.getCompletedDayCount(id);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAyahsForDay(int dayId) async {
    _currentDayAyahs = await ProgressionDbHelper.getAyahsForDay(dayId);
    notifyListeners();
  }

  Future<void> setCurrentAyah(ProgressionAyahModel ayah) async {
    _currentAyah = ayah;
    notifyListeners();
  }

  Future<void> markAyahStatus(int ayahId, String status) async {
    await ProgressionDbHelper.updateAyahStatus(ayahId, status);

    // If marking completed, check if day is done
    if (status == 'completed') {
      // Next ayah stays 'pending' — the UI promotes it visually

      // Check if all ayahs in the current day are completed
      await _checkAndCompleteDayIfNeeded();
    }

    // Reload day ayahs
    if (_currentDayAyahs.isNotEmpty) {
      await loadAyahsForDay(_currentDayAyahs.first.dayId);
    }

    // Refresh counts
    if (_progression?.id != null) {
      _completedAyahCount = await ProgressionDbHelper.getCompletedAyahCount(
        _progression!.id!,
      );
      _completedDayCount = await ProgressionDbHelper.getCompletedDayCount(
        _progression!.id!,
      );
    }
    notifyListeners();
  }

  Future<void> _checkAndCompleteDayIfNeeded() async {
    if (_currentDayAyahs.isEmpty) return;
    final dayId = _currentDayAyahs.first.dayId;

    // Re-fetch the ayahs to check current state
    final freshAyahs = await ProgressionDbHelper.getAyahsForDay(dayId);
    final allCompleted = freshAyahs.every((a) => a.status == 'completed');

    if (allCompleted) {
      await ProgressionDbHelper.updateDayStatus(dayId, 'completed');

      // Find the current day index and unlock the next day
      final dayIdx = _days.indexWhere((d) => d.id == dayId);
      if (dayIdx >= 0 && dayIdx < _days.length - 1) {
        final nextDay = _days[dayIdx + 1];
        await ProgressionDbHelper.updateDayStatus(nextDay.id!, 'reading');

        // Unlock the first ayah of the next day
        final nextDayAyahs = await ProgressionDbHelper.getAyahsForDay(
          nextDay.id!,
        );
        if (nextDayAyahs.isNotEmpty) {
          await ProgressionDbHelper.updateAyahStatus(
            nextDayAyahs.first.id!,
            'reading',
          );
        }
      }

      // Reload days
      if (_progression?.id != null) {
        _days = await ProgressionDbHelper.getDaysForProgression(
          _progression!.id!,
        );
      }
    }
  }

  Future<void> updateReminder({
    required String time,
    required List<String> days,
  }) async {
    if (_progression == null) return;
    final updated = _progression!.copyWith(
      reminderTime: time,
      reminderDays: jsonEncode(days),
    );
    await ProgressionDbHelper.updateProgression(updated);
    await ProgressionNotificationService.updateReminders(
      progressionId: _progression!.id!,
      time: time,
      days: days,
      surahName: _progression!.surahName,
    );
    _progression = updated;
    notifyListeners();
  }

  void clear() {
    _progression = null;
    _days = [];
    _currentDayAyahs = [];
    _currentAyah = null;
    _completedAyahCount = 0;
    _completedDayCount = 0;
    notifyListeners();
  }
}
