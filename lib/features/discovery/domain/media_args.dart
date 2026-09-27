import 'package:shonenx/shared/models/unified_media.dart';

class MediaArgs {
  final String mediaTitle;
  final MediaType type;
  final String? sourceId;
  final String? providerId;
  final String? mediaId;
  final String? mediaIdMal;
  final String? mediaTitleRomaji;
  final String? mediaTitleNative;
  final MediaExternalIds? externalIds;

  const MediaArgs({
    required this.mediaTitle,
    required this.type,
    this.sourceId,
    this.providerId,
    this.mediaId,
    this.mediaIdMal,
    this.mediaTitleRomaji,
    this.mediaTitleNative,
    this.externalIds,
  });

  MediaArgs copyWith({
    String? mediaTitle,
    MediaType? type,
    String? sourceId,
    String? providerId,
    String? mediaId,
    String? mediaIdMal,
    String? mediaTitleRomaji,
    String? mediaTitleNative,
    MediaExternalIds? externalIds,
  }) {
    return MediaArgs(
      mediaTitle: mediaTitle ?? this.mediaTitle,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      providerId: providerId ?? this.providerId,
      mediaId: mediaId ?? this.mediaId,
      mediaIdMal: mediaIdMal ?? this.mediaIdMal,
      mediaTitleRomaji: mediaTitleRomaji ?? this.mediaTitleRomaji,
      mediaTitleNative: mediaTitleNative ?? this.mediaTitleNative,
      externalIds: externalIds ?? this.externalIds,
    );
  }

  /// Recommended factory when a [UnifiedMedia] is available.
  factory MediaArgs.fromMedia(UnifiedMedia media) {
    return MediaArgs(
      mediaTitle: media.title.getPreferedTitle,
      type: media.type,
      sourceId: media.sourceId,
      providerId: media.sourceId != null
          ? (media.providerId ?? media.id)
          : null,
      mediaId: media.id,
      mediaIdMal: media.idMal,
      mediaTitleRomaji: media.title.romaji,
      mediaTitleNative: media.title.native,
      externalIds: media.externalIds,
    );
  }

  /// Convenience factory for title-only contexts (e.g. history, notifications).
  factory MediaArgs.fromTitle(
    String title, {
    required MediaType type,
    String? sourceId,
    String? providerId,
  }) {
    return MediaArgs(
      mediaTitle: title,
      type: type,
      sourceId: sourceId,
      providerId: providerId,
    );
  }

  UnifiedMedia toMedia() {
    return UnifiedMedia(
      id: mediaId ?? '',
      idMal: mediaIdMal,
      providerId: providerId,
      sourceId: sourceId,
      type: type,
      externalIds: externalIds ?? const MediaExternalIds(),
      title: MediaTitle(
        english: mediaTitle,
        romaji: mediaTitleRomaji,
        native: mediaTitleNative,
      ),
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
