import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class EpisodeThumbnail extends StatelessWidget {
  final String? episodeThumbnail;
  final String? fallbackUrl;
  final int episodeNumber;
  final bool isWatched;
  final double aspectRatio;

  const EpisodeThumbnail({
    super.key,
    this.episodeThumbnail,
    this.fallbackUrl,
    required this.episodeNumber,
    required this.isWatched,
    this.aspectRatio = 16 / 9,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (episodeThumbnail != null)
              episodeThumbnail!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: episodeThumbnail!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildFallbackIcon(theme),
                    )
                  : _buildBase64Image(theme, episodeThumbnail!)
            else if (fallbackUrl != null && fallbackUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: fallbackUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _buildFallbackIcon(theme),
              )
            else
              Container(color: theme.colorScheme.surfaceContainer),

            // Ep Number Overlay
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$episodeNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (isWatched)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 30,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBase64Image(ThemeData theme, String base64String) {
    try {
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(theme),
      );
    } catch (e) {
      return _buildFallbackIcon(theme);
    }
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_not_supported, color: theme.colorScheme.outline),
    );
  }
}
