import 'package:shonenx/shared/models/unified_media.dart';

/// Context arguments used to identify media when resolving preferences,
/// matching across sources, and fetching episodes.
class MediaArgs {
  final String mediaTitle;
  final MediaType type;
  final String? sourceId;
  final String? providerId;

  const MediaArgs({
    required this.mediaTitle,
    required this.type,
    this.sourceId,
    this.providerId,
  });

  factory MediaArgs.fromMedia(UnifiedMedia media) {
    return MediaArgs(
      mediaTitle: media.title.availableTitle,
      type: media.type,
      sourceId: media.sourceId,
      providerId:
          media.providerId ?? (media.sourceId != null ? media.id : null),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaArgs &&
          mediaTitle == other.mediaTitle &&
          type == other.type &&
          sourceId == other.sourceId &&
          providerId == other.providerId;

  @override
  int get hashCode => Object.hash(mediaTitle, type, sourceId, providerId);
}

@Deprecated('Use MediaArgs instead')
typedef MatchArgs = MediaArgs;
