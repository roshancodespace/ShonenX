import 'dart:ui' as ui;
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';

class ThemePaletteItem {
  final String id;
  final String label;
  final String? subtitle;
  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color tertiary;
  final Color? surface;

  const ThemePaletteItem({
    required this.id,
    required this.label,
    this.subtitle,
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.tertiary,
    this.surface,
  });

  factory ThemePaletteItem.fromFlexScheme({
    required FlexScheme scheme,
    required FlexSchemeData data,
    required bool isDark,
  }) {
    final colors = isDark ? data.dark : data.light;
    return ThemePaletteItem(
      id: scheme.name,
      label: data.name,
      subtitle: data.description,
      primary: colors.primary,
      primaryContainer: colors.primaryContainer,
      secondary: colors.secondary,
      tertiary: colors.tertiary,
    );
  }

  factory ThemePaletteItem.fromExclusive({
    required String key,
    required ExclusiveSchemeData data,
    required bool isDark,
  }) {
    final colors = isDark ? data.dark : data.light;
    return ThemePaletteItem(
      id: key,
      label: data.name,
      subtitle: data.description,
      primary: colors.primary,
      primaryContainer: colors.primaryContainer,
      secondary: colors.secondary,
      tertiary: colors.tertiary,
    );
  }

  factory ThemePaletteItem.fromSeed({
    required String id,
    required String label,
    required Color seedColor,
    required bool isDark,
    String? subtitle,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    return ThemePaletteItem(
      id: id,
      label: label,
      subtitle:
          subtitle ??
          '#${(seedColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
      primary: scheme.primary,
      primaryContainer: scheme.primaryContainer,
      secondary: scheme.secondary,
      tertiary: scheme.tertiary,
    );
  }
}

class ThemePaletteCard extends StatelessWidget {
  final ThemePaletteItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double height;

  const ThemePaletteCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.width = 136,
    this.height = 94,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    return Material(
      color: isSelected
          ? cs.primaryContainer.withValues(alpha: 0.35)
          : cs.surfaceContainerLow.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: isSelected
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.2),
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildDot(item.primary),
                      const SizedBox(width: 3),
                      _buildDot(item.primaryContainer),
                      const SizedBox(width: 3),
                      _buildDot(item.secondary),
                      const SizedBox(width: 3),
                      _buildDot(item.tertiary),
                    ],
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: cs.primary,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      item.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                        fontFeatures: const [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
    );
  }
}

class ThemePaletteTile extends StatelessWidget {
  final ThemePaletteItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  const ThemePaletteTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 0.0, vertical: 3.0),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    return Padding(
      padding: margin,
      child: Material(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.35)
            : cs.surfaceContainerLow.withValues(alpha: 0.65),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: isSelected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.2),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(radius * 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDot(item.primary),
                      const SizedBox(width: 4),
                      _buildDot(item.primaryContainer),
                      const SizedBox(width: 4),
                      _buildDot(item.secondary),
                      const SizedBox(width: 4),
                      _buildDot(item.tertiary),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                      if (item.subtitle != null &&
                          item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle_rounded, size: 20, color: cs.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
    );
  }
}

class ThemePaletteShelf extends StatelessWidget {
  final String title;
  final String? countBadge;
  final List<ThemePaletteItem> items;
  final String? selectedId;
  final ValueChanged<ThemePaletteItem> onSelect;
  final VoidCallback? onViewAll;
  final double cardWidth;
  final double cardHeight;
  final EdgeInsetsGeometry? padding;

  const ThemePaletteShelf({
    super.key,
    required this.title,
    this.countBadge,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.onViewAll,
    this.cardWidth = 136,
    this.cardHeight = 94,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: cs.primary,
                    ),
                  ),
                  if (countBadge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(radius * 0.6),
                      ),
                      child: Text(
                        countBadge!,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return ThemePaletteCard(
                  item: item,
                  isSelected: selectedId == item.id,
                  onTap: () => onSelect(item),
                  width: cardWidth,
                  height: cardHeight,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
