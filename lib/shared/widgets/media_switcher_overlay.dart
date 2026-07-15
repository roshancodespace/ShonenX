import 'package:flutter/material.dart';

class MediaSwitcherOverlay extends StatelessWidget {
  final TabController controller;
  final VoidCallback? onSearchTap;
  final bool isSearchActive;

  const MediaSwitcherOverlay({
    super.key,
    required this.controller,
    this.onSearchTap,
    this.isSearchActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final hasSearch = onSearchTap != null && !isSearchActive;

        return Container(
          height: 48,
          padding: EdgeInsets.only(
            left: 4,
            top: 4,
            bottom: 4,
            right: hasSearch ? 8 : 4,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MediaTabPill(
                label: 'Anime',
                icon: Icons.movie_outlined,
                isSelected: controller.index == 0,
                onTap: () => controller.animateTo(0),
              ),
              _MediaTabPill(
                label: 'Manga',
                icon: Icons.menu_book_outlined,
                isSelected: controller.index == 1,
                onTap: () => controller.animateTo(1),
              ),
              if (hasSearch) ...[
                const VerticalDivider(
                  width: 16,
                  indent: 6,
                  endIndent: 6,
                  thickness: 1,
                ),
                IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  iconSize: 20,
                  tooltip: 'Search',
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onSearchTap,
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
