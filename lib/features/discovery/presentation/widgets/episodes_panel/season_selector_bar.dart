import 'package:flutter/material.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_focus_hover.dart';
import 'package:shonenx/shared/widgets/marquee_text.dart';

class SeasonSelectorBar extends StatelessWidget {
  final UnifiedMedia currentMedia;

  const SeasonSelectorBar({super.key, required this.currentMedia});

  @override
  Widget build(BuildContext context) {
    final relations = currentMedia.relations;
    if (relations == null || relations.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter relevant relations (same media type, excluding non-media entries)
    final validRelations = relations.where((r) {
      if (r.type != currentMedia.type) return false;
      final rel = r.relationType?.toUpperCase();
      if (rel == 'CHARACTER' || rel == 'ADAPTATION') return false;
      return true;
    }).toList();

    if (validRelations.isEmpty) {
      return const SizedBox.shrink();
    }

    final prequels = validRelations
        .where((r) => r.relationType?.toUpperCase() == 'PREQUEL')
        .toList();
    final sequels = validRelations
        .where((r) => r.relationType?.toUpperCase() == 'SEQUEL')
        .toList();
    final others = validRelations.where((r) {
      final t = r.relationType?.toUpperCase();
      return t != 'PREQUEL' && t != 'SEQUEL';
    }).toList();

    final items = <Widget>[];

    // 1. Prequels (chronologically before current media)
    for (final rel in prequels) {
      items.add(
        _SeasonPill(
          icon: Icons.skip_previous_rounded,
          tag: 'Prequel',
          title: rel.title.availableTitle,
          onTap: () => _navigateToRelation(context, rel),
        ),
      );
    }

    // 2. Current Media (active)
    items.add(
      _SeasonPill(
        icon: Icons.check_rounded,
        tag: 'Current',
        title: currentMedia.title.availableTitle,
        isCurrent: true,
      ),
    );

    // 3. Sequels (chronologically after current media)
    for (final rel in sequels) {
      items.add(
        _SeasonPill(
          icon: Icons.skip_next_rounded,
          tag: 'Sequel',
          title: rel.title.availableTitle,
          onTap: () => _navigateToRelation(context, rel),
        ),
      );
    }

    // 4. Other related entries (Side stories, Spin-offs, Movies, etc.)
    for (final rel in others) {
      final (tag, icon) = _getRelationMeta(rel);
      items.add(
        _SeasonPill(
          icon: icon,
          tag: tag,
          title: rel.title.availableTitle,
          onTap: () => _navigateToRelation(context, rel),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              items[i],
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToRelation(BuildContext context, UnifiedMedia rel) {
    context.pushDetails(mediaType: rel.type, media: rel, initialTabIndex: 1);
  }

  (String, IconData) _getRelationMeta(UnifiedMedia rel) {
    if (rel.format?.toUpperCase() == 'MOVIE') {
      return ('Movie', Icons.movie_rounded);
    }
    switch (rel.relationType?.toUpperCase()) {
      case 'PARENT':
        return ('Main Series', Icons.account_tree_rounded);
      case 'SIDE_STORY':
        return ('Side Story', Icons.alt_route_rounded);
      case 'SPIN_OFF':
        return ('Spin-off', Icons.hub_rounded);
      case 'ALTERNATIVE':
        return ('Alternative', Icons.shuffle_rounded);
      case 'SUMMARY':
        return ('Summary', Icons.summarize_rounded);
      default:
        return ('Related', Icons.layers_outlined);
    }
  }
}

class _SeasonPill extends StatelessWidget {
  final IconData icon;
  final String tag;
  final String title;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _SeasonPill({
    required this.icon,
    required this.tag,
    required this.title,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final radius = BorderRadius.circular(GlobalUI.uiRoundness.clamp(8.0, 20.0));

    if (isCurrent) {
      return Material(
        color: cs.primary,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: cs.onPrimary),
              const SizedBox(width: 6),
              Text(
                tag,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              if (title.isNotEmpty) ...[
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.onPrimary.withValues(alpha: 0.6),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: MarqueeText(
                    text: title,
                    velocity: 28.0,
                    style:
                        textTheme.labelMedium?.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w500,
                        ) ??
                        TextStyle(color: cs.onPrimary, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return AppFocusHover(
      onTap: onTap,
      scaleFactor: 1.04,
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;
        return Material(
          color: active
              ? cs.surfaceContainerHighest
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: active
                    ? cs.primary.withValues(alpha: 0.6)
                    : cs.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: active ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  tag,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: active
                        ? cs.primary
                        : cs.primary.withValues(alpha: 0.85),
                    letterSpacing: 0.2,
                  ),
                ),
                if (title.isNotEmpty) ...[
                  Container(
                    width: 3,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: MarqueeText(
                      text: title,
                      velocity: 28.0,
                      style:
                          textTheme.labelMedium?.copyWith(
                            color: active ? cs.onSurface : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ) ??
                          TextStyle(
                            color: active ? cs.onSurface : cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
