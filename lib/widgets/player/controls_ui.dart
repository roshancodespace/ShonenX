import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/models/subtitle_style_offline_model.dart';
import 'settings_ui.dart';

class ControlsUI extends StatelessWidget {
  final AnimationController fadeController;
  final bool controlsVisible;
  final bool showSettings;
  final Player player;
  final bool isFullScreen;
  final ValueNotifier<bool> isPlaying;
  final ValueNotifier<bool> isBuffering;
  final ValueNotifier<Duration> position;
  final ValueNotifier<Duration> duration;
  final ValueNotifier<double> volume;
  final ValueNotifier<double> playbackSpeed;
  final anime_media.Media animeMedia;
  final List<EpisodeDataModel> episodes;
  final int currentEpisodeIndex;
  final List<SubtitleTrack> subtitles;
  final ValueNotifier<SubtitleStyle> subtitleStyle;
  final VoidCallback onResetHideTimer;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onToggleSettings;

  const ControlsUI({
    super.key,
    required this.fadeController,
    required this.controlsVisible,
    required this.showSettings,
    required this.player,
    required this.isFullScreen,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    required this.volume,
    required this.playbackSpeed,
    required this.animeMedia,
    required this.episodes,
    required this.currentEpisodeIndex,
    required this.subtitles,
    required this.subtitleStyle,
    required this.onResetHideTimer,
    required this.onToggleFullScreen,
    required this.onToggleSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: controlsVisible ? null : onResetHideTimer,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          if (controlsVisible)
            FadeTransition(
              opacity: fadeController,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(theme, context),
                      const Spacer(),
                      _buildPlaybackControls(theme),
                      const Spacer(),
                      _buildBottomControls(theme, context),
                    ],
                  ),
                ),
              ),
            ),
          StreamBuilder<List<String>>(
            stream: player.stream.subtitle,
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty ||
                  snapshot.data!.join('').trim().isEmpty) {
                return const SizedBox.shrink();
              }

              String subtitleText = snapshot.data!.join('\n');

              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: ValueListenableBuilder<SubtitleStyle>(
                    valueListenable: subtitleStyle,
                    builder: (context, style, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withValues(alpha: style.backgroundOpacity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subtitleText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: style.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: style.fontSize,
                            shadows: style.hasShadow
                                ? [
                                    const Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 4,
                                      color: Colors.black,
                                    ),
                                  ]
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          // Remove SettingsUI from Stack; it’s now a modal
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Iconsax.arrow_left_1, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              animeMedia.title?.english ?? animeMedia.title?.romaji ?? '',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Iconsax.backward_10_seconds,
              color: Colors.white, size: 28),
          onPressed: () =>
              player.seek(position.value - const Duration(seconds: 10)),
        ),
        const SizedBox(width: 24),
        ValueListenableBuilder<bool>(
          valueListenable: isBuffering,
          builder: (context, buffering, _) => buffering
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : ValueListenableBuilder<bool>(
                  valueListenable: isPlaying,
                  builder: (context, playing, _) => IconButton(
                    icon: Icon(
                      playing ? Iconsax.pause : Iconsax.play,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () => playing ? player.pause() : player.play(),
                  ),
                ),
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(Iconsax.forward_10_seconds,
              color: Colors.white, size: 28),
          onPressed: () =>
              player.seek(position.value + const Duration(seconds: 10)),
        ),
      ],
    );
  }

  Widget _buildBottomControls(ThemeData theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          ValueListenableBuilder<Duration>(
            valueListenable: duration,
            builder: (context, dur, _) => ValueListenableBuilder<Duration>(
              valueListenable: position,
              builder: (context, pos, _) => SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                  thumbColor: Colors.white,
                  overlayColor:
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
                child: Slider(
                  value: pos.inSeconds
                      .toDouble()
                      .clamp(0.0, dur.inSeconds.toDouble()),
                  min: 0.0,
                  max: dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0,
                  onChanged: (value) =>
                      player.seek(Duration(seconds: value.toInt())),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<Duration>(
                valueListenable: position,
                builder: (context, pos, _) => ValueListenableBuilder<Duration>(
                  valueListenable: duration,
                  builder: (context, dur, _) => Text(
                    '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ),
              ),
              Row(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: volume,
                    builder: (context, vol, _) => IconButton(
                      icon: Icon(
                        vol == 0 ? Iconsax.volume_mute : Iconsax.volume_high,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => player.setVolume(vol == 0 ? 100 : 0),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: onToggleFullScreen,
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.setting_2,
                        color: Colors.white, size: 20),
                    onPressed: () {
                      onToggleSettings(); // Toggle _showSettings for consistency
                      showSettingsUI(
                        context: context,
                        theme: theme,
                        player: player,
                        volume: volume,
                        playbackSpeed: playbackSpeed,
                        subtitles: subtitles,
                        subtitleStyle: subtitleStyle,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
