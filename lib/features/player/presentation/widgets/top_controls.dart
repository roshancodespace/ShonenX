import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/keyboard_shortcuts_sheet.dart';
import 'package:shonenx/features/player/presentation/widgets/player_controls.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/settings/presentation/widgets/subtitle_settings_sheet.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

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
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 600;

    final animeTitle = mode is PlayerModeOnline
        ? (mode as PlayerModeOnline).media.title.getPreferedTitle
        : (mode as PlayerModeOffline).title ?? 'Local Media';

    final episodeNumber = playerState.activeEpisode?.number;
    final formattedEp = formatEpisodeNumber(episodeNumber);
    final episodeTitle = playerState.activeEpisode?.title;

    final String subtitleText;
    if (episodeTitle != null && episodeTitle.isNotEmpty) {
      subtitleText = formattedEp != null
          ? 'Episode $formattedEp • $episodeTitle'
          : episodeTitle;
    } else if (formattedEp != null) {
      subtitleText = 'Episode $formattedEp';
    } else {
      subtitleText = mode is PlayerModeOffline ? 'Offline File' : 'Episode 1';
    }

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          animeTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4.0,
                color: Colors.black87,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitleText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            shadows: const [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4.0,
                color: Colors.black87,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final showQuality =
        mode is PlayerModeOnline && playerState.qualities.length > 1;
    final showComments = mode is PlayerModeOnline && onComments != null;

    final actionButtons = <Widget>[
      if (showQuality) ...[
        PlayerQualityButton(
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
        const SizedBox(width: 8),
      ],
      if (showComments && !isCompact) ...[
        PlayerIconButton(
          icon: Icons.comment_outlined,
          size: 22,
          padding: const EdgeInsets.all(8.0),
          tooltip: 'Comments',
          onTap: onComments!,
        ),
        const SizedBox(width: 4),
      ],
      if (!isCompact) ...[
        PlayerIconButton(
          icon: switch (ref.watch(
            videoEngineStateProvider.select((s) => s.fit),
          )) {
            BoxFit.contain => Icons.fit_screen_rounded,
            BoxFit.cover => Icons.aspect_ratio_rounded,
            _ => Icons.fullscreen_exit_rounded,
          },
          size: 22,
          padding: const EdgeInsets.all(8.0),
          tooltip: 'Aspect Ratio',
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
        const SizedBox(width: 4),
        PlayerIconButton(
          icon: Icons.camera_alt_outlined,
          size: 22,
          padding: const EdgeInsets.all(8.0),
          tooltip: 'Screenshot',
          onTap: () async {
            final result = await ref
                .read(playerControllerProvider.notifier)
                .takeAndShareScreenshot();
            if (context.mounted && result.message != 'Save cancelled') {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        ),
        const SizedBox(width: 4),
      ],
      PlayerIconButton(
        icon: Icons.settings_outlined,
        size: 22,
        padding: const EdgeInsets.all(8.0),
        tooltip: 'Player Settings',
        onTap: () => _showUnifiedSettingsSheet(context, ref, isCompact),
      ),
    ];

    return AnimatedPositioned(
      duration: Durations.medium2,
      curve: Curves.fastEaseInToSlowEaseOut,
      top: showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: Durations.short4,
        opacity: showControls ? 1 : 0,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 24,
                top: 8,
                left: 14,
                right: 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PlayerIconButton(
                    icon: Icons.arrow_back_ios_new_outlined,
                    size: 24,
                    padding: const EdgeInsets.all(8.0),
                    tooltip: 'Back',
                    onTap: onBack,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: titleColumn),
                  const SizedBox(width: 12),
                  Row(mainAxisSize: MainAxisSize.min, children: actionButtons),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnifiedSettingsSheet(
    BuildContext context,
    WidgetRef ref,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final currentFit = ref.read(videoEngineStateProvider).fit;
    final fitLabel = switch (currentFit) {
      BoxFit.contain => 'Fit Screen (Contain)',
      BoxFit.cover => 'Fill Screen (Cover)',
      _ => 'Stretch (Fill)',
    };

    final currentSpeed = playerState.playbackSpeed;
    final speedLabel = currentSpeed == 1.0
        ? 'Normal (1.0x)'
        : '${currentSpeed}x';

    final activeQualityText = playerState.activeQuality?.quality ?? 'Auto';
    final hasMultipleQualities =
        mode is PlayerModeOnline && playerState.qualities.length > 1;

    AppBottomSheet.show(
      context: context,
      title: 'Player Settings',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(
              title: 'Playback',
              children: [
                SettingsActionTile(
                  icon: Icons.speed_rounded,
                  title: 'Playback Speed',
                  subtitle: speedLabel,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        speedLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    AppBottomSheet.showSelector<double>(
                      context: context,
                      title: 'Playback Speed',
                      items: const [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
                      selectedValue: currentSpeed,
                      itemLabel: (speed) =>
                          speed == 1.0 ? 'Normal (1.0x)' : '${speed}x',
                      onChanged: (speed) {
                        controller.changeSpeed(speed);
                      },
                    );
                  },
                ),
                if (hasMultipleQualities)
                  SettingsActionTile(
                    icon: Icons.high_quality_rounded,
                    title: 'Video Quality',
                    subtitle: activeQualityText,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activeQualityText.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
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
                SettingsActionTile(
                  icon: Icons.aspect_ratio_rounded,
                  title: 'Video Aspect Ratio',
                  subtitle: fitLabel,
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
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
              ],
            ),
            SettingsSection(
              title: 'Customization & Engine',
              children: [
                SettingsNavTile(
                  icon: Icons.subtitles_outlined,
                  title: 'Subtitle Customization',
                  subtitle: 'Adjust font, colors, size, and background',
                  onTap: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      constraints: const BoxConstraints(
                        maxWidth: double.infinity,
                      ),
                      builder: (context) => const SubtitleSettingsSheet(),
                    );
                  },
                ),
                if (engine.buildSettingsView(context) != null)
                  SettingsNavTile(
                    icon: Icons.video_settings_outlined,
                    title: 'Decoder & Engine Settings',
                    subtitle: 'Hardware decoding, audio output, and caching',
                    onTap: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (context) =>
                            engine.buildSettingsView(context)!,
                      );
                    },
                  ),
                SettingsNavTile(
                  icon: Icons.keyboard_alt_outlined,
                  title: 'Keyboard Shortcuts',
                  subtitle: 'View shortcuts and hotkey bindings',
                  onTap: () {
                    Navigator.of(context).pop();
                    KeyboardShortcutsSheet.show(context);
                  },
                ),
              ],
            ),
            if (isCompact &&
                ((mode is PlayerModeOnline && onComments != null) || true))
              SettingsSection(
                title: 'Quick Actions',
                children: [
                  if (mode is PlayerModeOnline && onComments != null)
                    SettingsNavTile(
                      icon: Icons.comment_outlined,
                      title: 'Discussion & Comments',
                      subtitle: 'Open episode discussion panel',
                      onTap: () {
                        Navigator.of(context).pop();
                        onComments!();
                      },
                    ),
                  SettingsActionTile(
                    icon: Icons.camera_alt_outlined,
                    title: 'Take Screenshot',
                    subtitle: 'Capture and share current frame',
                    onTap: () async {
                      Navigator.of(context).pop();
                      final result = await ref
                          .read(playerControllerProvider.notifier)
                          .takeAndShareScreenshot();
                      if (context.mounted &&
                          result.message != 'Save cancelled') {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
