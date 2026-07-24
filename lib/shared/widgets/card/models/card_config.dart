import 'package:flutter/material.dart';

class CardConfig {
  final double width;
  final double height;
  final bool isActive;
  final bool isLoading;
  final bool isWideMode;

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? heroTag;

  final double? progress;
  final String? progressText;

  final String? badgeText;
  final Widget? topRightBadge;
  final String? bottomLeftBadgeText;
  final double? score;

  final String? year;
  final String? status;
  final List<String>? genres;

  final IconData fallbackIcon;
  final Widget Function(BuildContext context, ColorScheme cs)? thumbnailBuilder;

  const CardConfig({
    required this.width,
    required this.height,
    required this.isActive,
    required this.title,
    this.isLoading = false,
    this.isWideMode = false,
    this.subtitle,
    this.imageUrl,
    this.heroTag,
    this.progress,
    this.progressText,
    this.badgeText,
    this.topRightBadge,
    this.bottomLeftBadgeText,
    this.score,
    this.year,
    this.status,
    this.genres,
    this.fallbackIcon = Icons.image_not_supported_rounded,
    this.thumbnailBuilder,
  });

  String? get effectiveSubtitle {
    if (subtitle != null && subtitle!.isNotEmpty) return subtitle!;
    final items = <String>[];
    if (year != null && year!.isNotEmpty) items.add(year!);
    if (status != null && status!.isNotEmpty) items.add(status!);
    if (genres != null && genres!.isNotEmpty) items.add(genres!.first);
    if (items.isEmpty) return null;
    return items.join(' • ');
  }

  String? get formattedScore {
    if (score == null || score! <= 0) return null;
    return score! > 10
        ? (score! / 10).toStringAsFixed(1)
        : score!.toStringAsFixed(1);
  }
}
