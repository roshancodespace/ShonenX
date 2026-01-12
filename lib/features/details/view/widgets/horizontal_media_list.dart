import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/shared/widgets/focusable_tap.dart';
import 'package:shonenx/shared/widgets/app_scale.dart';

class HorizontalMediaSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final bool isLoading;
  final Widget Function(BuildContext, T) itemBuilder;
  final VoidCallback? onMoreTap;

  const HorizontalMediaSection({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && items.isEmpty) return const SizedBox.shrink();
    final scale = AppScaleScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (onMoreTap != null)
                TextButton(
                  onPressed: onMoreTap,
                  child: const Text('More'),
                ),
            ],
          ),
        ),
        SizedBox(height: 16 * scale),
        SizedBox(
          height: 200 * scale,
          child: isLoading && items.isEmpty
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  cacheExtent: 10000 * scale,
                  padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                  itemCount: 4,
                  separatorBuilder: (_, __) => SizedBox(width: 12 * scale),
                  itemBuilder: (_, __) => const _ShimmerItem(),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  cacheExtent: 10000 * scale,
                  padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox(width: 12 * scale),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return itemBuilder(context, item);
                  },
                ),
        ),
      ],
    );
  }
}

class MediaCard extends StatelessWidget {
  final UniversalMedia media;
  final String? badgeText;
  final VoidCallback? onTap;

  const MediaCard({
    super.key,
    required this.media,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScaleScope.of(context);
    final radius = BorderRadius.circular(12 * scale);

    // Get the best available title
    final title = media.title.english ?? media.title.romaji ?? 'Unknown';

    return FocusableTap(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        width: 130 * scale,
        decoration: BoxDecoration(
          borderRadius: radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: radius,
                    child: CachedNetworkImage(
                      imageUrl: media.coverImage.large ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceContainer,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainer,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: theme.colorScheme.outline,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  if (badgeText != null)
                    Positioned(
                      top: 8 * scale,
                      left: 8 * scale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6 * scale),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8 * scale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4 * scale),
              child: Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerItem extends StatelessWidget {
  const _ShimmerItem();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scale = AppScaleScope.of(context);
    final radius = BorderRadius.circular(12 * scale);

    return Container(
      width: 130 * scale,
      decoration: BoxDecoration(
        borderRadius: radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: radius,
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12 * scale,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4 * scale),
                  ),
                ),
                SizedBox(height: 4 * scale),
                Container(
                  height: 12 * scale,
                  width: 80 * scale,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4 * scale),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StaffCard extends StatelessWidget {
  final UniversalStaff staff;
  final VoidCallback? onTap;

  const StaffCard({
    super.key,
    required this.staff,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScaleScope.of(context);
    final radius = BorderRadius.circular(12 * scale);
    final name = staff.name?.full ?? staff.name?.native ?? 'Unknown';
    final role = staff.role ?? 'Staff';

    return FocusableTap(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        width: 130 * scale,
        decoration: BoxDecoration(
          borderRadius: radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: radius,
                child: CachedNetworkImage(
                  imageUrl: staff.image?.large ?? staff.image?.medium ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceContainer,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainer,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.outline,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8 * scale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    role,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
