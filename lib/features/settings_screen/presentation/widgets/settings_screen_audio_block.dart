import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/platform_helper.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_selector_dropdown.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';

const int _reciterVisibleItemCount = 4;
const double _reciterMenuItemHeight = 48;
const double _reciterMenuHeight =
  _reciterVisibleItemCount * _reciterMenuItemHeight;

class SettingsScreenAudioBlock extends StatelessWidget {
  const SettingsScreenAudioBlock({super.key});

  Widget _buildMobileReciterSelector(
    BuildContext context,
    PlaySettingsProvider playSettings,
    TextStyle reciterTextStyle,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: accentColor, size: 22),
              const SizedBox(width: 16),
              Text(
                'Reciters',
                style: AppTextTheme.drawerStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: playSettings.selectedReciterIndex,
                    isExpanded: true,
                    isDense: true,
                    itemHeight: _reciterMenuItemHeight,
                    menuMaxHeight: _reciterMenuHeight,
                    menuWidth: constraints.maxWidth,
                    dropdownColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade900
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 22,
                    ),
                    style: reciterTextStyle,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    selectedItemBuilder: (context) {
                      return PlaySettingsProvider.reciters
                          .map(
                            (reciter) => Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                reciter.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: reciterTextStyle,
                              ),
                            ),
                          )
                          .toList();
                    },
                    onChanged: (value) {
                      if (value != null) {
                        playSettings.setReciter(value);
                      }
                    },
                    items: List.generate(
                      PlaySettingsProvider.reciters.length,
                      (index) => DropdownMenuItem<int>(
                        value: index,
                        child: Text(
                          PlaySettingsProvider.reciters[index].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: reciterTextStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebReciterSelector(
    BuildContext context,
    PlaySettingsProvider playSettings,
    TextStyle reciterTextStyle,
  ) {
    return SettingsScreenSelectorDropdown<int>(
      title: 'Reciters',
      icon: Icons.person,
      value: playSettings.selectedReciterIndex,
      items: List.generate(
        PlaySettingsProvider.reciters.length,
        (index) => SettingsScreenSelectorItem<int>(
          value: index,
          label: PlaySettingsProvider.reciters[index].name,
        ),
      ),
      buttonLabelWidth: 250,
      menuLabelWidth: 280,
      labelTextStyle: reciterTextStyle,
      onSelected: (index) {
        playSettings.setReciter(index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = appBarAccentColor(context);
    final accentTrackColor = appBarAccentFillColor(context, alpha: 0.35);
    final reciterTextStyle = AppTextTheme.drawerStyle.copyWith(
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.15,
    );

    return Consumer<PlaySettingsProvider>(
      builder: (context, playSettings, _) {
        return SettingsScreenCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Reciter picker ──────────────────────────────────
              PlatformHelper.isWeb
                  ? _buildWebReciterSelector(
                      context,
                      playSettings,
                      reciterTextStyle,
                    )
                  : _buildMobileReciterSelector(
                      context,
                      playSettings,
                      reciterTextStyle,
                      accentColor,
                    ),

              // ── Translation visibility ────────────────────────
              SettingsScreenListTile(
                title: 'Show Translation',
                icon: Icons.translate,
                trailing: Switch(
                  value: playSettings.showTranslation,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentTrackColor,
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
                        Icon(Icons.speed, color: accentColor, size: 22),
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
                        Icon(Icons.queue_music, color: accentColor, size: 22),
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
    final accentColor = appBarAccentColor(context);
    final accentFillColor = appBarAccentFillColor(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? accentFillColor : Colors.transparent,
          border: Border.all(
            color: selected ? accentColor : Colors.grey.shade400,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? accentColor : Colors.grey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? accentColor : Colors.grey,
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

