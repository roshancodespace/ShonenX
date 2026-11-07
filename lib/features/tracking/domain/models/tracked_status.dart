import 'package:flutter/widgets.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
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

  String getLocalizedLabel(BuildContext context, [bool isManga = false]) {
    final l10n = context.l10n;
    switch (this) {
      case TrackedStatus.watching:
        return isManga
            ? l10n.trackingStatusReading
            : l10n.trackingStatusWatching;
      case TrackedStatus.planning:
        return isManga
            ? l10n.trackingStatusPlanToRead
            : l10n.trackingStatusPlanToWatch;
      case TrackedStatus.completed:
        return l10n.trackingStatusCompleted;
      case TrackedStatus.paused:
        return l10n.trackingStatusOnHold;
      case TrackedStatus.dropped:
        return l10n.trackingStatusDropped;
      case TrackedStatus.unknown:
        return l10n.commonUnknown;
    }
  }

  String getLocalizedLabelForMedia(BuildContext context, MediaType? mediaType) {
    return getLocalizedLabel(context, mediaType == MediaType.MANGA);
  }
}
