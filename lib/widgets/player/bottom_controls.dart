import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/providers/watch_providers.dart';
import 'package:shonenx/utils/formatter.dart';
import 'package:shonenx/widgets/ui/shonenx_dropdown.dart';
import 'package:shonenx/widgets/ui/shonenx_icon_btn.dart';
import 'dart:developer' as developer;

class BottomControls extends StatelessWidget {
  static const _padding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static final _borderRadius = BorderRadius.circular(10);

  final AnimeProvider animeProvider;
  final WatchState watchState;
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onPlayPause;
  final Duration position;
  final Duration duration;
  final VoidCallback onChangeSource;

  const BottomControls({
    required this.animeProvider,
    required this.watchState,
    required this.isPlaying,
    required this.onPlayPause,
    required this.position,
    required this.duration,
    required this.isBuffering,
    required this.onChangeSource,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSources = watchState.sources.isNotEmpty;
    final sourceQuality = hasSources
        ? watchState.sources[watchState.selectedSourceIdx ?? 0].quality ??
            'default'
        : 'Loading...';

    return Container(
      padding: _padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShonenXIconButton(
            icon: isPlaying ? Iconsax.pause : Iconsax.play,
            tooltip: isPlaying ? 'Pause' : 'Play',
            onPressed: onPlayPause,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            // size: 32,
          ),
          const SizedBox(width: 16),
          _TimeDisplay(
            position: position,
            duration: duration,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          _SettingsButton(
            theme: theme,
            enabled: true,
            label: '${watchState.selectedServer ?? 'N/A'}, '
                '${watchState.selectedCategory ?? 'N/A'}, '
                '$sourceQuality',
            onTap: () => _showSettingsPanel(context, position: position),
          ),
        ],
      ),
    );
  }

  void _showSettingsPanel(BuildContext context, {required Duration position}) {
    developer.log('Showing settings panel', name: 'BottomControls');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) => _SettingsPanel(
        animeProvider: animeProvider,
        watchState: watchState,
        position: position,
        onClose: () => Navigator.of(modalContext).pop(),
      ),
    ).whenComplete(
        () => developer.log('Settings panel closed', name: 'BottomControls'));
  }
}

class _TimeDisplay extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final TextStyle? style;

  const _TimeDisplay(
      {required this.position, required this.duration, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${formatDuration(position)} / ${formatDuration(duration)}',
      style: style,
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final ThemeData theme;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  const _SettingsButton({
    required this.theme,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.setting_4,
              size: 14,
              color: enabled ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: enabled ? Colors.white70 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPanel extends ConsumerWidget {
  static const _padding = EdgeInsets.all(16);
  static const _cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)));

  final AnimeProvider animeProvider;
  final WatchState watchState;
  final Duration position;
  final VoidCallback onClose;

  const _SettingsPanel({
    required this.animeProvider,
    required this.watchState,
    required this.position,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final episodeIdx = watchState.selectedEpisodeIdx ?? 0;
    final hasEpisodes = watchState.episodes.isNotEmpty;
    final episodeTitle = hasEpisodes
        ? watchState.episodes[episodeIdx].title ?? 'Untitled'
        : 'Loading...';

    return Padding(
      padding: _padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: 'Video Settings',
            theme: theme,
            onClose: onClose,
          ),
          const SizedBox(height: 8),
          Text(
            'Episode ${hasEpisodes ? watchState.episodes[episodeIdx].number : 'N/A'}: $episodeTitle',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            theme: theme,
            children: [
              if (animeProvider.getDubSubParamSupport())
                _SettingsRow(
                  icon: Iconsax.language_circle,
                  label: 'Category',
                  theme: theme,
                  child: ShonenxDropdown(
                      icon: Iconsax.language_circle,
                      value: watchState.selectedCategory ?? 'sub',
                      items: const ['dub', 'sub'],
                      onChanged: (value) => ref
                          .read(watchProvider.notifier)
                          .changeCategory(value)),
                ),
              if (animeProvider.getSupportedServers().isNotEmpty &&
                  animeProvider.getSupportedServers().length > 1)
                _SettingsRow(
                  icon: Iconsax.devices,
                  label: 'Servers',
                  theme: theme,
                  child: ShonenxDropdown(
                      icon: Iconsax.devices,
                      value: watchState.selectedServer ?? 'Default',
                      items: animeProvider.getSupportedServers(),
                      onChanged: (value) =>
                          ref.read(watchProvider.notifier).changeServer(value)),
                ),
              if (watchState.sources.isNotEmpty &&
                  watchState.sources.length > 1)
                _SettingsRow(
                  icon: Iconsax.cloud,
                  label: 'Sources',
                  theme: theme,
                  child: ShonenxDropdown(
                    icon: Iconsax.cloud,
                    value: watchState.sources[watchState.selectedSourceIdx ?? 0]
                            .quality ??
                        'Default',
                    items: watchState.sources
                        .map((source) => source.quality ?? 'Default')
                        .toList(),
                    onChanged: (value) => _handleQualityChange(value, ref),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleQualityChange(String? value, WidgetRef ref) {
    if (value == null) return;
    final index =
        watchState.sources.indexWhere((source) => source.quality == value);
    if (index != -1) {
      ref
          .read(watchProvider.notifier)
          .changeSource(sourceIdx: index, lastPosition: position);
    }
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;
  final VoidCallback onClose;

  const _PanelHeader(
      {required this.title, required this.theme, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        IconButton(
          icon: Icon(
            Iconsax.close_circle,
            size: 24,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final ThemeData theme;
  final List<Widget> children;

  const _SettingsCard({required this.theme, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: _SettingsPanel._cardShape,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: children.isNotEmpty
              ? [
                  ...children
                      .expand((child) => [
                            child,
                            const SizedBox(height: 12),
                          ])
                      .toList()
                    ..removeLast(),
                ]
              : [const SizedBox.shrink()],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final ThemeData theme;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.child,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
