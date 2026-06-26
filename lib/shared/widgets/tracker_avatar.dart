import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TrackerAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const TrackerAvatarWidget({
    super.key,
    required this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl?.trim() ?? '';

    if (url.isEmpty) {
      return _fallback(theme);
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallback(theme),
      );
    }

    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(theme),
        );
      }
    } catch (_) {}

    return _fallback(theme);
  }

  Widget _fallback(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        color: theme.colorScheme.onPrimaryContainer,
        size: size * 0.52,
      ),
    );
  }
}
