import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/provider/progression_tracker_provider.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/services/progression_notification_service.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';

class AddProgressionScreen extends StatefulWidget {
  const AddProgressionScreen({super.key});

  @override
  State<AddProgressionScreen> createState() => _AddProgressionScreenState();
}

class _AddProgressionScreenState extends State<AddProgressionScreen> {
  SurahModel? _selectedSurah;
  int? _selectedDays;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  final List<String> _allDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  late List<String> _selectedReminderDays;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedReminderDays = List.from(_allDays);
  }

  List<int> _getDayOptions() {
    if (_selectedSurah == null) return [];
    final totalAyahs = _selectedSurah!.ayathCount;
    final options = <int>[];
    for (int d = 1; d <= totalAyahs; d++) {
      final ayahsPerDay = (totalAyahs / d).ceil();
      if (ayahsPerDay >= 1) {
        options.add(d);
      }
      // Limit options to reasonable numbers
      if (d > 30 && d < totalAyahs) continue;
    }
    // Show sensible options: 1, 2, 3, 5, 7, 10, 14, 21, 30, and totalAyahs
    final sensible = <int>{1, 2, 3, 5, 7, 10, 14, 21, 30, totalAyahs};
    return sensible.where((d) => d <= totalAyahs).toList()..sort();
  }

  String _dayLabel(int days) {
    if (_selectedSurah == null) return '$days days';
    final ayahsPerDay = (_selectedSurah!.ayathCount / days).ceil();
    return '$days days ( $ayahsPerDay ayath/day)';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _startLearning() async {
    if (_selectedSurah == null || _selectedDays == null) return;
    setState(() => _isSaving = true);

    await context.read<ProgressionTrackerProvider>().addProgression(
      surahNumber: _selectedSurah!.surahNumber,
      surahName: _selectedSurah!.name,
      arabicName: _selectedSurah!.arabicName,
      place: _selectedSurah!.place,
      totalAyahs: _selectedSurah!.ayathCount,
      totalDays: _selectedDays!,
      reminderTime: ProgressionNotificationService.parseDisplayTime(
        _reminderTime,
      ),
      reminderDays: _selectedReminderDays,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Start Progression header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.appIconTheme.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Start Progression',
                style: TextStyle(
                  color: AppTheme.appIconTheme,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Surah info card (visible when surah is selected)
            if (_selectedSurah != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.appIconTheme.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.appIconTheme.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedSurah!.arabicName,
                      style: TextStyle(
                        fontSize: 20,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedSurah!.name,
                      style: TextStyle(
                        fontSize: 18,
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total Ayah : ${_selectedSurah!.ayathCount} Ayat   |   ${_selectedSurah!.place}',
                      style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Select Surah
            Text(
              'Select Surah',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<SurahProvider>(
              builder: (context, surahProv, _) {
                final surahs = surahProv.surahList;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: Text(
                        'Select Surah',
                        style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                      ),
                      value: _selectedSurah?.surahNumber,
                      dropdownColor: cardBg,
                      items: surahs.map((s) {
                        return DropdownMenuItem<int>(
                          value: s.surahNumber,
                          child: Text(
                            '${s.surahNumber} - ${s.arabicName.isNotEmpty ? s.arabicName : s.name}',
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedSurah = surahs.firstWhere(
                            (s) => s.surahNumber == val,
                          );
                          _selectedDays = null;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Select Days
            Text(
              'Select days',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  hint: Text(
                    _selectedSurah == null
                        ? 'Select a surah first'
                        : 'Select days',
                    style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  ),
                  value: _selectedDays,
                  dropdownColor: cardBg,
                  items: _getDayOptions().map((d) {
                    return DropdownMenuItem<int>(
                      value: d,
                      child: Text(
                        _dayLabel(d),
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }).toList(),
                  onChanged: _selectedSurah == null
                      ? null
                      : (val) => setState(() => _selectedDays = val),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Reminder time
            Text(
              'Reminder time',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: textColor.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _reminderTime.format(context),
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Reminder days
            Text(
              'Reminder days',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allDays.map((day) {
                final selected = _selectedReminderDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedReminderDays.remove(day);
                      } else {
                        _selectedReminderDays.add(day);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.appIconTheme
                          : cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.appIconTheme
                            : borderColor,
                      ),
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        color: selected ? Colors.white : textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // Start Learning button
            Center(
              child: ElevatedButton(
                onPressed: (_selectedSurah != null &&
                        _selectedDays != null &&
                        !_isSaving)
                    ? _startLearning
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.appIconTheme,
                  disabledBackgroundColor:
                      AppTheme.appIconTheme.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Start',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
