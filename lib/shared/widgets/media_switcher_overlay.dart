import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class MediaSwitcherOverlay extends StatelessWidget {
  final TabController controller;
  final VoidCallback? onSearchTap;
  final bool isSearchActive;
  final List<MediaType> supportedTypes;

  const MediaSwitcherOverlay({
    super.key,
    required this.controller,
    this.onSearchTap,
    this.isSearchActive = false,
    this.supportedTypes = const [MediaType.ANIME, MediaType.MANGA],
  });

  BoxDecoration _buildDecoration(ColorScheme colorScheme, double radius) {
    return BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final roundness = GlobalUI.uiRoundness;
    final innerRadius = (roundness - 4).clamp(0.0, roundness);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final hasSearch = onSearchTap != null && !isSearchActive;

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: _buildDecoration(colorScheme, roundness),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < supportedTypes.length; i++)
                          _MediaTabPill(
                            type: supportedTypes[i],
                            isSelected: controller.index == i,
                            uiRoundness: innerRadius,
                            onTap: () => controller.animateTo(i),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasSearch) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSearchTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: _buildDecoration(colorScheme, roundness),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

extension on MediaType {
  String get label => switch (this) {
    MediaType.TV => 'TV',
    _ => displayName,
  };

  IconData get icon => switch (this) {
    MediaType.ANIME => Icons.movie_outlined,
    MediaType.MANGA => Icons.menu_book_outlined,
    MediaType.NOVEL => Icons.menu_book_rounded,
    MediaType.TV => Icons.tv_outlined,
    MediaType.MOVIE => Icons.local_movies_outlined,
  };
}

class _MediaTabPill extends StatelessWidget {
  final MediaType type;
  final bool isSelected;
  final double uiRoundness;
  final VoidCallback onTap;

  const _MediaTabPill({
    required this.type,
    required this.isSelected,
    required this.uiRoundness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(uiRoundness),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 18,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
