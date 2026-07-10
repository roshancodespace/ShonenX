import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/keyboard_shortcuts_sheet.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/settings/presentation/widgets/subtitle_settings_sheet.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/models/video_stream.dart';

class TopControls extends ConsumerWidget {
  final bool showControls;
  final PlayerMode mode;
  final VideoEngine engine;
  final PlayerState playerState;
  final PlayerController controller;
  final VoidCallback onBack;
  final VoidCallback? onComments;

  const TopControls({
    super.key,
    required this.showControls,
    required this.mode,
    required this.engine,
    required this.playerState,
    required this.controller,
    required this.onBack,
    this.onComments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedPositioned(
      duration: Durations.medium2,
      curve: Curves.fastEaseInToSlowEaseOut,
      top: showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: Durations.short4,
        opacity: showControls ? 1 : 0,
        child: Container(
          padding: const EdgeInsets.only(
            bottom: 40,
            top: 20,
            left: 10,
            right: 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black,
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildActionIcon(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mode is PlayerModeOnline
                          ? (mode as PlayerModeOnline)
                                .media
                                .title
                                .availableTitle
                          : (mode as PlayerModeOffline).title ?? 'Local Media',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 4.0,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      playerState.activeEpisode?.title ??
                          'Episode ${formatEpisodeNumber(playerState.activeEpisode?.number) ?? (mode is PlayerModeOffline ? 'Offline File' : 'N/A')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 4.0,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (mode is PlayerModeOnline &&
                  playerState.qualities.length > 1) ...[
                _buildQualityButton(
                  qualityText: playerState.activeQuality?.quality ?? 'Auto',
                  onTap: () {
                    AppBottomSheet.showSelector<VideoStream>(
                      context: context,
                      title: 'Select Quality',
                      items: playerState.qualities,
                      selectedValue: playerState.activeQuality,
                      itemLabel: (s) => s.quality,
                      onChanged: (v) {
                        controller.changeQuality(v);
                      },
                    );
                  },
                ),
                const SizedBox(width: 6),
              ],
              if (mode is PlayerModeOnline && onComments != null) ...[
                _buildActionIcon(
                  icon: Icons.comment_outlined,
                  onTap: onComments!,
                ),
                const SizedBox(width: 6),
              ],
              _buildActionIcon(
                icon: switch (ref.watch(
                  videoEngineStateProvider.select((s) => s.fit),
                )) {
                  BoxFit.contain => Icons.fit_screen_rounded,
                  BoxFit.cover => Icons.aspect_ratio_rounded,
                  _ => Icons.fullscreen_exit_rounded,
                },
                onTap: () {
                  ref.read(videoEngineStateProvider.notifier).cycleFit();
                  final newFit = ref.read(videoEngineStateProvider).fit;
                  final label = switch (newFit) {
                    BoxFit.contain => 'Fit Screen (Contain)',
                    BoxFit.cover => 'Fill Screen (Cover)',
                    _ => 'Stretch (Fill)',
                  };
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Video Fit: $label'),
                      duration: const Duration(milliseconds: 1200),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              _buildActionIcon(
                icon: Icons.keyboard_alt_outlined,
                onTap: () => KeyboardShortcutsSheet.show(context),
              ),
              const SizedBox(width: 6),
              _buildActionIcon(
                icon: Icons.tune_rounded,
                onTap: () => _showPlayerOptionsMenu(context),
              ),
              const SizedBox(width: 6),
              if (engine.buildSettingsView(context) != null)
                _buildActionIcon(
                  icon: Icons.video_settings_outlined,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => engine.buildSettingsView(context)!,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerOptionsMenu(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: 'Player Options',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.subtitles_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Subtitle Customization',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Adjust font, colors, size, and background',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                constraints: const BoxConstraints(maxWidth: double.infinity),
                builder: (context) => const SubtitleSettingsSheet(),
              );
            },
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: Icon(
              Icons.speed_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Playback Speed',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              playerState.playbackSpeed == 1.0
                  ? 'Normal (1.0x)'
                  : '${playerState.playbackSpeed}x',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              Navigator.of(context).pop();
              AppBottomSheet.showSelector<double>(
                context: context,
                title: 'Playback Speed',
                items: const [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
                selectedValue: playerState.playbackSpeed,
                itemLabel: (speed) =>
                    speed == 1.0 ? 'Normal (1.0x)' : '${speed}x',
                onChanged: (speed) {
                  controller.changeSpeed(speed);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildQualityButton({
    required String qualityText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              qualityText.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
              size: 6,
            ),
          ],
        ),
      ),
    );
  }
}
