import 'package:shonenx/shared/models/unified_media.dart';

/// Context arguments used to identify media when resolving preferences,
/// matching across sources, and fetching episodes.
///
/// - Always prefer [MediaArgs.fromMedia] when a [UnifiedMedia] instance is available.
/// - For title-only contexts (e.g. history entries, notifications), use [MediaArgs.fromTitle].
class MediaArgs {
  /// The primary title used for preferences lookup and search-based matching.
  final String mediaTitle;

  /// Media type (Anime, Manga, etc.).
  final MediaType type;

  /// Non-null only if the media originated directly from an extension source.
  final String? sourceId;

  /// The content ID on the extension source (e.g. "/category/naruto")
  /// when originating directly from a source. Null for AniList/catalog media.
  final String? providerId;

  /// Canonical catalog ID (e.g. AniList ID).
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

  /// Recommended factory when a [UnifiedMedia] is available.
  factory MediaArgs.fromMedia(UnifiedMedia media) {
    return MediaArgs(
      mediaTitle: media.title.availableTitle,
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
