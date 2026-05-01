import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/reminder_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/wakelock_provider.dart';

class SettingsScreenAppBlock extends StatelessWidget {
  const SettingsScreenAppBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final wakelockProvider = context.watch<WakelockProvider>();
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        return SettingsScreenCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsScreenListTile(
                title: 'Keep Screen On',
                icon: Icons.light_mode_outlined,
                trailing: Switch.adaptive(
                  value: wakelockProvider.keepScreenOn,
                  activeThumbColor: AppTheme.appIconTheme,
                  onChanged: (value) {
                    wakelockProvider.toggleKeepScreenOn(value);
                  },
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SettingsScreenListTile(
                title: 'Daily Reminder',
                icon: Icons.notifications_outlined,
                trailing: Switch.adaptive(
                  value: provider.isEnabled,
                  activeThumbColor: AppTheme.appIconTheme,
                  onChanged: (value) async {
                    final success = await provider.toggleReminder(value);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Notification permission is required for reminders.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              if (provider.isEnabled) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                SettingsScreenListTile(
                  title: 'Reminder Time',
                  icon: Icons.access_time,
                  trailing: GestureDetector(
                    onTap: () => _pickTime(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.appIconTheme.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        provider.time.format(context),
                        style:const TextStyle(
                          color: AppTheme.appIconTheme,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    ReminderProvider provider,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: provider.time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dayPeriodColor: AppTheme.appIconTheme,
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black;
              }),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await provider.setTime(picked);
    }
  }
}
