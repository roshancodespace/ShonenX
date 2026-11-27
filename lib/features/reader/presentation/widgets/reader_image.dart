import 'dart:typed_data';

import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

class ReaderImage extends StatelessWidget {
  final String url;
  final Map<String, String>? headers;
  final Uint8List? bytes;
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
    this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    BoxFit fit = BoxFit.fitWidth;
    if (scaleType == ReaderScaleType.fitHeight) {
      fit = BoxFit.fitHeight;
    } else if (scaleType == ReaderScaleType.original) {
      fit = BoxFit.contain;
    }

    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: fit,
        width: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => SizedBox(
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

    return SmartImage(
      imageUrl: url,
      httpHeaders: headers,
      fit: fit,
      width: double.infinity,
      memCacheWidth: 1400,
      maxWidthDiskCache: 1800,
      progressIndicatorBuilder: (context, url, progress) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: AppProgressIndicator(type: AppProgressType.circular, value: progress.progress, strokeWidth: 2),
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
