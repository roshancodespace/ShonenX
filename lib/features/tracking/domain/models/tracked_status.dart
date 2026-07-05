import 'package:shonenx/shared/models/unified_media.dart';

enum TrackedStatus {
  watching('Watching'),
  planning('Plan to Watch'),
  completed('Completed'),
  paused('Paused'),
  dropped('Dropped'),
  unknown('Unknown');

  final String displayName;
  const TrackedStatus(this.displayName);

  String get id => name;

  String getLabel([bool isManga = false]) {
    if (isManga) {
      if (this == TrackedStatus.watching) return 'Reading';
      if (this == TrackedStatus.planning) return 'Plan to Read';
    }
    return displayName;
  }

  String getLabelForMedia(MediaType? mediaType) {
    return getLabel(mediaType == MediaType.MANGA);
  }
}
