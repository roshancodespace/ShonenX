import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/providers/watch_providers.dart';
import 'package:shonenx/widgets/ui/shonenx_icon_btn.dart';

class TopControls extends StatelessWidget {
  final WatchState watchState;
  final VoidCallback onPanelToggle;
  final VoidCallback onQualityTap;
  final VoidCallback onSubtitleTap;
  final Future<void> Function() onFullscreenTap;

  const TopControls({
    super.key,
    required this.watchState,
    required this.onPanelToggle,
    required this.onQualityTap,
    required this.onSubtitleTap,
    required this.onFullscreenTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);
    final contentColor = theme.colorScheme.onSurfaceVariant;
    final containerColor =
        Colors.black38; // Slightly darker for better contrast

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button and title container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  ShonenXIconButton(
                    icon: Iconsax.arrow_left_1,
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    backgroundColor: buttonColor,
                    foregroundColor: contentColor,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          watchState.episodes.isNotEmpty
                              ? (watchState
                                      .episodes[
                                          watchState.selectedEpisodeIdx ?? 0]
                                      .title ??
                                  'No Title')
                              : 'Loading...',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                        if (watchState.episodes.isNotEmpty &&
                            watchState.selectedEpisodeIdx != null)
                          Text(
                            'Episode ${watchState.selectedEpisodeIdx! + 1}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Control buttons container
          Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildControlButton(
                  icon: Iconsax.video,
                  tooltip: 'Quality',
                  isEnabled: watchState.qualityOptions.isNotEmpty,
                  onPressed: onQualityTap,
                  buttonColor: buttonColor,
                  contentColor: contentColor,
                  badgeCount: watchState.qualityOptions.length,
                ),
                const SizedBox(width: 10),
                _buildControlButton(
                    icon: Iconsax.subtitle,
                    tooltip: 'Subtitles',
                    isEnabled: watchState.subtitles.isNotEmpty,
                    onPressed: onSubtitleTap,
                    buttonColor: buttonColor,
                    contentColor: contentColor,
                    badgeCount: watchState.subtitles.length),
                const SizedBox(width: 10),
                _buildControlButton(
                  icon: Iconsax.maximize_4,
                  tooltip: 'Fullscreen',
                  isEnabled: true,
                  onPressed: onFullscreenTap,
                  buttonColor: buttonColor,
                  contentColor: contentColor,
                ),
                const SizedBox(width: 10),
                _buildControlButton(
                  icon: Iconsax.menu_1,
                  tooltip: 'Episodes',
                  isEnabled: true,
                  onPressed: onPanelToggle,
                  buttonColor: theme.colorScheme.primaryContainer,
                  contentColor: theme.colorScheme.onPrimaryContainer,
                  isHighlighted: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required bool isEnabled,
    required VoidCallback? onPressed,
    required Color buttonColor,
    required Color contentColor,
    bool isHighlighted = false,
    int? badgeCount,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ShonenXIconButton(
          icon: icon,
          tooltip: tooltip,
          onPressed: isEnabled ? onPressed : null,
          backgroundColor: buttonColor,
          foregroundColor: contentColor,
          // elevation: isHighlighted ? 4 : 2,
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
