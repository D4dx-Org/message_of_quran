import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';

class SettingsScreenAudioBlock extends StatelessWidget {
  const SettingsScreenAudioBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaySettingsProvider>(
      builder: (context, playSettings, _) {
        return SettingsScreenCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Reciter picker ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person,
                            color: AppTheme.appIconTheme, size: 22),
                        const SizedBox(width: 16),
                        Text(
                          'Reciter',
                          style: AppTextTheme.drawerStyle
                              .copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return DropdownMenu<int>(
                          width: constraints.maxWidth,
                          inputDecorationTheme: const InputDecorationTheme(
                              border: InputBorder.none),
                          initialSelection:
                              playSettings.selectedReciterIndex,
                          textStyle: AppTextTheme.drawerStyle
                              .copyWith(fontWeight: FontWeight.w500),
                          menuStyle: MenuStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey.shade900
                                  : Colors.white,
                            ),
                          ),
                          onSelected: (value) {
                            if (value != null){
                               playSettings.setReciter(value);
                            }
                             
                          },
                          dropdownMenuEntries: List.generate(
                            PlaySettingsProvider.reciters.length,
                            (index) => DropdownMenuEntry<int>(
                              value: index,
                              label: PlaySettingsProvider
                                  .reciters[index].name,
                              style: ButtonStyle(
                                textStyle: WidgetStatePropertyAll(
                                  AppTextTheme.drawerStyle.copyWith(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Translation visibility ────────────────────────
              SettingsScreenListTile(
                title: 'Show Translation',
                icon: Icons.translate,
                trailing: Switch(
                  value: playSettings.showTranslation,
                  activeThumbColor: AppTheme.appIconTheme,
                  onChanged: (v) => playSettings.setShowTranslation(v),
                ),
              ),

              // ── Playback speed ───────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed,
                            color: AppTheme.appIconTheme, size: 22),
                        const SizedBox(width: 16),
                        Text(
                          'Playback Speed',
                          style: AppTextTheme.drawerStyle
                              .copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: PlaySettingsProvider.speedPresets
                          .map((speed) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: _ModeChip(
                                    label: '${speed}x',
                                    icon: Icons.speed,
                                    selected: playSettings.playbackSpeed ==
                                        speed,
                                    onTap: () =>
                                        playSettings.setPlaybackSpeed(speed),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              // ── Play mode ────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.queue_music,
                            color: AppTheme.appIconTheme, size: 22),
                        const SizedBox(width: 16),
                        Text(
                          'Play Mode',
                          style: AppTextTheme.drawerStyle
                              .copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ModeChip(
                            label: 'Single Block',
                            icon: Icons.looks_one_outlined,
                            selected: playSettings.playMode ==
                                PlayMode.singleBlock,
                            onTap: () =>
                                playSettings.setPlayMode(PlayMode.singleBlock),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ModeChip(
                            label: 'Continuous',
                            icon: Icons.repeat,
                            selected: playSettings.playMode ==
                                PlayMode.continuous,
                            onTap: () =>
                                playSettings.setPlayMode(PlayMode.continuous),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.appIconTheme.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppTheme.appIconTheme : Colors.grey.shade400,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppTheme.appIconTheme : Colors.grey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? AppTheme.appIconTheme : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

