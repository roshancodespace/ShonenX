import 'package:flutter/material.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_focus_hover.dart';
import 'package:shonenx/shared/widgets/marquee_text.dart';

class SeasonSelectorBar extends StatelessWidget {
  final UnifiedMedia currentMedia;

  const SeasonSelectorBar({super.key, required this.currentMedia});

  // Matches "Season 2", "S2"
  static final _seasonRegex = RegExp(
    r'\b(?:Season|S)\s*(\d+)\b',
    caseSensitive: false,
  );

  // Matches ordinal names like "2nd Season", "3rd Season"
  static final _ordinalSeasonRegex = RegExp(
    r'\b(\d+)(?:st|nd|rd|th)\s*Season\b',
    caseSensitive: false,
  );

  // Matches split-cours like "Part 2"
  static final _partRegex = RegExp(r'\bPart\s*(\d+)\b', caseSensitive: false);

  // Matches "Final Season"
  static final _finalSeasonRegex = RegExp(
    r'\bFinal\s*Season\b',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final relations = currentMedia.relations;
    if (relations == null || relations.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter to valid prequel/sequel seasons of the same media type
    final validRelations = relations.where((r) {
      if (r.type != currentMedia.type) return false;
      final rel = r.relationType?.toUpperCase();
      if (rel != 'PREQUEL' && rel != 'SEQUEL') return false;

      final fmt = r.format?.toUpperCase();
      if (fmt == 'MUSIC' || fmt == 'SPECIAL' || fmt == 'MOVIE') return false;

      return true;
    }).toList();

    if (validRelations.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort chronologically by release year
    final prequels =
        validRelations
            .where((r) => r.relationType?.toUpperCase() == 'PREQUEL')
            .toList()
          ..sort((a, b) => (a.year ?? 0).compareTo(b.year ?? 0));

    final sequels =
        validRelations
            .where((r) => r.relationType?.toUpperCase() == 'SEQUEL')
            .toList()
          ..sort((a, b) => (a.year ?? 0).compareTo(b.year ?? 0));

    // Hide if no other seasons exist
    if (prequels.isEmpty && sequels.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = <Widget>[
      for (final rel in prequels)
        _SeasonPill(
          icon: Icons.skip_previous_rounded,
          tag: _resolveSeasonTag(rel, fallback: 'Prequel'),
          title: rel.title.availableTitle,
          onTap: () => _navigateToRelation(context, rel),
        ),
      _SeasonPill(
        icon: Icons.check_rounded,
        tag: _resolveSeasonTag(currentMedia, fallback: 'Current'),
        title: currentMedia.title.availableTitle,
        isCurrent: true,
      ),
      for (final rel in sequels)
        _SeasonPill(
          icon: Icons.skip_next_rounded,
          tag: _resolveSeasonTag(rel, fallback: 'Sequel'),
          title: rel.title.availableTitle,
          onTap: () => _navigateToRelation(context, rel),
        ),
    ];

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
    context.pushReplacementDetails(
      mediaType: rel.type,
      media: rel,
      initialTabIndex: 1,
    );
  }

  String _resolveSeasonTag(UnifiedMedia media, {required String fallback}) {
    final title = media.title.availableTitle;

    // Check "Season 2" or "S2"
    final seasonMatch = _seasonRegex.firstMatch(title);
    if (seasonMatch != null) {
      return 'Season ${seasonMatch.group(1)}';
    }

    // Check "2nd Season"
    final ordSeasonMatch = _ordinalSeasonRegex.firstMatch(title);
    if (ordSeasonMatch != null) {
      return 'Season ${ordSeasonMatch.group(1)}';
    }

    // Check "Part 2"
    final partMatch = _partRegex.firstMatch(title);
    if (partMatch != null) {
      return 'Part ${partMatch.group(1)}';
    }

    // Check "Final Season"
    if (_finalSeasonRegex.hasMatch(title)) {
      return 'Final Season';
    }

    return fallback;
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
