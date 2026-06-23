import 'package:flutter/material.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/models/video_stream.dart';

class TopControls extends StatelessWidget {
  final bool showControls;
  final PlayerMode mode;
  final VideoEngine engine;
  final PlayerState playerState;
  final PlayerController controller;
  final VoidCallback onBack;

  const TopControls({
    super.key,
    required this.showControls,
    required this.mode,
    required this.engine,
    required this.playerState,
    required this.controller,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(width: 16),
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
                        letterSpacing: 0.5,
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
                          (mode is PlayerModeOffline ? 'Offline File' : 'N/A'),
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
              const SizedBox(width: 16),
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
                const SizedBox(width: 16),
              ],
              _buildActionIcon(
                icon: Icons.settings_outlined,
                onTap: () {
                  if (engine.buildSettingsView(context) == null) return;
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

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
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
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
