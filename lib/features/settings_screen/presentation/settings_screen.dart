import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_audio_tab.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_display_tab.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_general_tab.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BaseScreenLayout(
      child: Column(
        children: [
          // ── Tab Bar ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.appIconTheme,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.appIconTheme.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              dividerHeight: 0,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.palette_outlined, size: 18),
                  text: 'Display',
                  height: 52,
                ),
                Tab(
                  icon: Icon(Icons.headphones_outlined, size: 18),
                  text: 'Audio',
                  height: 52,
                ),
                Tab(
                  icon: Icon(Icons.settings_outlined, size: 18),
                  text: 'General',
                  height: 52,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // ── Tab Views ───────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SettingsDisplayTab(),
                SettingsAudioTab(),
                SettingsGeneralTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

