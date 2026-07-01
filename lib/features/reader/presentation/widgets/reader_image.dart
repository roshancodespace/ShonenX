import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';

class ReaderImage extends StatelessWidget {
  final String url;
  final Map<String, String>? headers;
  final int index;
  final ReaderScaleType scaleType;
  final Color textColor;

  const ReaderImage({
    super.key,
    required this.url,
    required this.index,
    required this.scaleType,
    required this.textColor,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = url.split('#').first;

    BoxFit fit = BoxFit.fitWidth;
    if (scaleType == ReaderScaleType.fitHeight) {
      fit = BoxFit.fitHeight;
    } else if (scaleType == ReaderScaleType.original) {
      fit = BoxFit.contain;
    }

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      httpHeaders: headers,
      fit: fit,
      width: double.infinity,
      progressIndicatorBuilder: (context, url, progress) => SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: CircularProgressIndicator(
            value: progress.progress,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.grey, size: 48),
            const SizedBox(height: 8),
            Text(
              'Failed to load page ${index + 1}',
              style: TextStyle(color: textColor.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
