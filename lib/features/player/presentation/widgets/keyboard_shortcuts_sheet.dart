import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';

class KeyboardShortcutsSheet extends ConsumerWidget {
  const KeyboardShortcutsSheet({super.key});

  static void show(BuildContext context) {
    AppDialog.show(
      context: context,
      maxWidth: 900,
      contentPadding: EdgeInsets.zero,
      showCloseButton: false,
      wrapScrollable: false,
      child: const KeyboardShortcutsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final showOnStart = ref.watch(
      playerPrefsProvider.select((s) => s.showShortcutsSheetOnStart),
    );

    final playbackShortcuts = [
      ('Space / K', 'Play / Pause video'),
      ('Right / L', 'Seek forward 10s'),
      ('Left / J', 'Seek backward 10s'),
      ('Up Arrow', 'Volume up +5%'),
      ('Down Arrow', 'Volume down -5%'),
    ];

    final navigationShortcuts = [
      ('N / PageDown', 'Next episode'),
      ('P / PageUp', 'Previous episode'),
      ('E / R-Click', 'Toggle episodes list'),
      ('Esc', 'Close panel / exit full'),
    ];

    final settingsShortcuts = [
      ('F / Enter', 'Toggle fullscreen'),
      ('S', 'Cycle aspect ratio'),
      ('] / [', 'Speed ±0.25x'),
      ('Backspace', 'Reset speed 1.0x'),
      ('? / F1', 'Show shortcuts guide'),
    ];

    return Container(
      padding: EdgeInsets.all(size.width < 500 ? 16 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.keyboard_rounded,
                      size: size.width < 500 ? 24 : 28,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keyboard Shortcuts & Controls',
                        style: TextStyle(
                          fontSize: size.width < 500 ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 24),
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                if (width > 680) {
                  // 3 Columns Widescreen Desktop Layout
                  return SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildSection(
                            theme,
                            'Playback Controls',
                            playbackShortcuts,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildSection(
                            theme,
                            'Navigation & Panels',
                            navigationShortcuts,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildSection(
                            theme,
                            'Video & Speed',
                            settingsShortcuts,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (width > 440) {
                  // 2 Columns Compact Desktop/Tablet Layout
                  return SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSection(
                                theme,
                                'Playback Controls',
                                playbackShortcuts,
                              ),
                              const SizedBox(height: 20),
                              _buildSection(
                                theme,
                                'Navigation & Panels',
                                navigationShortcuts,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildSection(
                            theme,
                            'Video & Speed',
                            settingsShortcuts,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // 1 Column Narrow / Portrait / Mobile Layout
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          theme,
                          'Playback Controls',
                          playbackShortcuts,
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          theme,
                          'Navigation & Panels',
                          navigationShortcuts,
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          theme,
                          'Video & Speed',
                          settingsShortcuts,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Always show this shortcuts guide on player startup',
              style: TextStyle(
                fontSize: size.width < 500 ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: size.width < 400
                ? null
                : const Text(
                    'Uncheck once you are familiar with the desktop controls',
                    style: TextStyle(fontSize: 12),
                  ),
            value: showOnStart,
            onChanged: (val) {
              ref
                  .read(playerPrefsProvider.notifier)
                  .toggleShowShortcutsSheetOnStart(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    List<(String, String)> shortcuts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        ...shortcuts.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    s.$1,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
