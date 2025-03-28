import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shonenx/data/hive/models/subtitle_style_offline_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// Function to show the settings UI as a modal bottom sheet
void showSettingsUI({
  required BuildContext context,
  required ThemeData theme,
  required Player player,
  required ValueNotifier<double> volume,
  required ValueNotifier<double> playbackSpeed,
  required List<SubtitleTrack> subtitles,
  required ValueNotifier<SubtitleStyle> subtitleStyle,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SettingsModal(
      theme: theme,
      player: player,
      volume: volume,
      playbackSpeed: playbackSpeed,
      subtitles: subtitles,
      subtitleStyle: subtitleStyle,
    ),
  );
}

class _SettingsModal extends StatefulWidget {
  final ThemeData theme;
  final Player player;
  final ValueNotifier<double> volume;
  final ValueNotifier<double> playbackSpeed;
  final List<SubtitleTrack> subtitles;
  final ValueNotifier<SubtitleStyle> subtitleStyle;

  const _SettingsModal({
    required this.theme,
    required this.player,
    required this.volume,
    required this.playbackSpeed,
    required this.subtitles,
    required this.subtitleStyle,
  });

  @override
  _SettingsModalState createState() => _SettingsModalState();
}

class _SettingsModalState extends State<_SettingsModal> {
  // ignore: unused_field
  int _currentSettingsPage = 0;
  String? _selectedSubtitle;

  @override
  void initState() {
    super.initState();
    _selectedSubtitle = widget.player.state.subtitle.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelStyle: widget.theme.textTheme.labelMedium,
                    unselectedLabelStyle: widget.theme.textTheme.labelSmall,
                    labelColor: widget.theme.colorScheme.primary,
                    unselectedLabelColor:
                        widget.theme.colorScheme.onSurfaceVariant,
                    indicatorColor: widget.theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Playback'),
                      Tab(text: 'Subtitles'),
                      Tab(text: 'Audio'),
                    ],
                    onTap: (index) =>
                        setState(() => _currentSettingsPage = index),
                  ),
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildPlaybackSettings(),
                        _buildSubtitleSettings(),
                        _buildAudioSettings(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Settings',
            style: widget.theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: Icon(Iconsax.close_circle,
                color: widget.theme.colorScheme.error, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Playback', style: widget.theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: widget.playbackSpeed,
            builder: (context, speed, _) {
              return Wrap(
                spacing: 6,
                children: [0.5, 1.0, 1.25, 1.5, 1.75, 2.0].map((s) {
                  return ChoiceChip(
                    label: Text('${s}x', style: const TextStyle(fontSize: 12)),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    selected: speed == s,
                    onSelected: (bool selected) {
                      if (selected) {
                        widget.playbackSpeed.value = s;
                        widget.player.setRate(s);
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitleSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subtitles', style: widget.theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          // Subtitle Track Selection
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Track', style: widget.theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: _selectedSubtitle,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text('None',
                            style: widget.theme.textTheme.bodySmall),
                      ),
                      ...widget.subtitles.map((subtitle) => DropdownMenuItem(
                            value: subtitle.language ?? 'Unknown',
                            child: Text(
                              subtitle.language ?? 'Unknown',
                              style: widget.theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSubtitle = value!;
                        if (value == '') {
                          widget.player.setSubtitleTrack(SubtitleTrack.no());
                        } else {
                          final selected = widget.subtitles.firstWhere(
                            (s) => s.language == value,
                            orElse: () => widget.subtitles.first,
                          );
                          widget.player.setSubtitleTrack(selected);
                        }
                      });
                    },
                    underline: const SizedBox(), // Remove default underline
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle Style Section
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ValueListenableBuilder<SubtitleStyle>(
                valueListenable: widget.subtitleStyle,
                builder: (context, style, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Style', style: widget.theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: style.backgroundOpacity),
                        border: Border.all(
                            color: widget.theme.colorScheme.outline, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Subtitle Preview',
                        style: TextStyle(
                          fontSize: style.fontSize,
                          color: style.textColor,
                          fontWeight: FontWeight.bold,
                          shadows: style.hasShadow
                              ? [
                                  const Shadow(
                                      offset: Offset(1, 1), blurRadius: 2)
                                ]
                              : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStyleRow(
                      label: 'Size',
                      child: DropdownButton<double>(
                        value: style.fontSize,
                        items: [12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0]
                            .map((size) => DropdownMenuItem(
                                  value: size,
                                  child: Text('$size px',
                                      style: widget.theme.textTheme.bodySmall),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            widget.subtitleStyle.value =
                                style.copyWith(fontSize: value);
                          }
                        },
                        underline: const SizedBox(),
                      ),
                    ),
                    _buildStyleRow(
                      label: 'Color',
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final newColor = await showDialog<Color>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Pick Color'),
                                  content: SingleChildScrollView(
                                    child: BlockPicker(
                                      pickerColor: style.textColor,
                                      onColorChanged: (color) =>
                                          Navigator.pop(context, color),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              );
                              if (newColor != null) {
                                widget.subtitleStyle.value =
                                    style.copyWith(textColor: newColor);
                              }
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: style.textColor,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Text Color',
                              style: widget.theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    _buildStyleRow(
                      label: 'Opacity',
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: style.backgroundOpacity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              label:
                                  '${(style.backgroundOpacity * 100).round()}%',
                              onChanged: (value) {
                                widget.subtitleStyle.value =
                                    style.copyWith(backgroundOpacity: value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(style.backgroundOpacity * 100).round()}%',
                            style: widget.theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _buildStyleRow(
                      label: 'Shadow',
                      child: Switch(
                        value: style.hasShadow,
                        onChanged: (value) {
                          widget.subtitleStyle.value =
                              style.copyWith(hasShadow: value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: widget.theme.textTheme.bodyMedium),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildAudioSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audio', style: widget.theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Iconsax.volume_high,
                  size: 20, color: widget.theme.colorScheme.onSurfaceVariant),
              Expanded(
                child: ValueListenableBuilder<double>(
                  valueListenable: widget.volume,
                  builder: (context, volume, _) {
                    return Slider(
                      value: volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        widget.volume.value = value;
                        widget.player.setVolume(value * 100);
                      },
                    );
                  },
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: widget.volume,
                builder: (context, volume, _) => Text(
                  '${(volume * 100).round()}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
