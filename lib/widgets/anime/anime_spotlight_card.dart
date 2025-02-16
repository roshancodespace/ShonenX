import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AnimeSpotlightCard extends StatelessWidget {
  final Media? anime;
  final Function(Media)? onTap;
  final String heroTag;

  const AnimeSpotlightCard({
    super.key,
    required this.anime,
    this.onTap,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: anime != null ? () => onTap?.call(anime!) : null,
        child: SizedBox(
          height: isSmallScreen ? 250 : 300,
          child: _buildCardContent(context, theme, isSmallScreen),
        ),
      ),
    );
  }

  Widget _buildCardContent(
      BuildContext context, ThemeData theme, bool isSmallScreen) {
    if (anime == null) {
      return _buildSkeleton(theme);
    }

    if (anime!.id == null) {
      return Center(
          child: CircularProgressIndicator(color: theme.primaryColor));
    }

    return _buildAnimeCard(context, theme, isSmallScreen);
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Skeletonizer.zone(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: theme.colorScheme.primaryContainer,
        highlightColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
      child: _SkeletonContent(theme: theme),
    );
  }

  Widget _buildAnimeCard(
      BuildContext context, ThemeData theme, bool isSmallScreen) {
    final imageUrl = anime?.bannerImage?.isNotEmpty == true
        ? anime!.bannerImage!
        : (anime?.coverImage?.large ?? anime!.coverImage?.medium ?? '');

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => _buildImagePlaceholder(theme),
      errorWidget: (_, url, error) => _buildImageError(theme, error, url),
      imageBuilder: (context, imageProvider) => _buildImageContent(
        context,
        theme,
        imageProvider,
        isSmallScreen,
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.1),
      child: Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      ),
    );
  }

  Widget _buildImageError(ThemeData theme, dynamic error, String url) {
    debugPrint('Image Load Error: $error for URL: $url');
    return Container(
      color: theme.colorScheme.error.withValues(alpha: 0.1),
      child:
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
    );
  }

  Widget _buildImageContent(
    BuildContext context,
    ThemeData theme,
    ImageProvider imageProvider,
    bool isSmallScreen,
  ) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [
              Colors.transparent,
              theme.shadowColor.withValues(alpha: 0.6)
            ],
          ),
        ),
        child: _AnimeContent(
          anime: anime!,
          isSmallScreen: isSmallScreen,
          theme: theme,
        ),
      ),
    );
  }
}

class _SkeletonContent extends StatelessWidget {
  final ThemeData theme;

  const _SkeletonContent({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Bone.text(),
          SizedBox(height: 10),
          Row(
            children: [
              Bone.text(words: 1),
              SizedBox(width: 10),
              Bone.text(words: 1),
            ],
          ),
          SizedBox(height: 10),
          Bone.multiText(lines: 2),
        ],
      ),
    );
  }
}

class _AnimeContent extends StatelessWidget {
  final Media anime;
  final bool isSmallScreen;
  final ThemeData theme;

  const _AnimeContent({
    required this.anime,
    required this.isSmallScreen,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const Spacer(),
        _buildTitle(),
        const SizedBox(height: 4),
        if (isSmallScreen) ...[
          _buildSmallScreenInfo(),
          const SizedBox(height: 4),
        ],
        _buildDescription(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildScoreChip(),
        const Spacer(),
        if (!isSmallScreen) _buildDetailedInfo(Theme.of(context)),
      ],
    );
  }

  Widget _buildScoreChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.star,
              color: theme.colorScheme.onPrimaryContainer, size: 15),
          const SizedBox(width: 4),
          Text(
            "${anime.averageScore ?? 'N/A'}",
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InfoItem(
          icon: Icon(
            Iconsax.play_circle,
            size: 15,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          label: anime.format ?? 'N/A',
          theme: theme,
        ),
        if (anime.duration != null) ...[
          const SizedBox(width: 10),
          _InfoItem(
            icon: Icon(
              Icons.timelapse_rounded,
              size: 15,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            label: '${anime.duration}m',
            theme: theme,
          ),
        ],
        if (anime.startDate?.year != null) ...[
          const SizedBox(width: 10),
          _InfoItem(
            icon: const Icon(Icons.date_range, size: 15),
            label: '${anime.startDate!.year}',
            theme: theme,
          ),
        ],
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      anime.title?.english ??
          anime.title?.native ??
          anime.title?.romaji ??
          'Untitled',
      style: (isSmallScreen
              ? theme.textTheme.titleMedium
              : theme.textTheme.titleLarge)
          ?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      maxLines: isSmallScreen ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSmallScreenInfo() {
    return Row(
      children: [
        _InfoItem(
          icon: const Icon(Icons.play_circle_fill, size: 14),
          label: anime.format ?? 'N/A',
          theme: theme,
        ),
        const SizedBox(width: 8),
        if (anime.duration != null)
          _InfoItem(
            icon: const Icon(Icons.timelapse, size: 14),
            label: anime.duration.toString(),
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      anime.description ?? 'N/A',
      style: (isSmallScreen
              ? theme.textTheme.bodySmall
              : theme.textTheme.bodyMedium)
          ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
      maxLines: isSmallScreen ? 2 : 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _InfoItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final ThemeData theme;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTheme(
          data: IconThemeData(color: theme.colorScheme.primary),
          child: icon,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
