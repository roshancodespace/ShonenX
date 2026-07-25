import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final hasSearch = onSearchTap != null && !isSearchActive;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.92,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...supportedTypes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final type = entry.value;

                          String label;
                          IconData icon;

                          switch (type) {
                            case MediaType.ANIME:
                              label = 'Anime';
                              icon = Icons.movie_outlined;
                              break;
                            case MediaType.MANGA:
                              label = 'Manga';
                              icon = Icons.menu_book_outlined;
                              break;
                            case MediaType.NOVEL:
                              label = 'Novel';
                              icon = Icons.menu_book_rounded;
                              break;
                            case MediaType.TV:
                              label = 'TV';
                              icon = Icons.tv_outlined;
                              break;
                            case MediaType.MOVIE:
                              label = 'Movie';
                              icon = Icons.local_movies_outlined;
                              break;
                          }

                          return _MediaTabPill(
                            label: label,
                            icon: icon,
                            isSelected: controller.index == index,
                            onTap: () => controller.animateTo(index),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasSearch) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSearchTap,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.92,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
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

class _MediaTabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MediaTabPill({
    required this.label,
    required this.icon,
    required this.isSelected,
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
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
