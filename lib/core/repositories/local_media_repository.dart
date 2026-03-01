import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart'
    hide Track, isar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/data/isar/media.dart';
import 'package:shonenx/data/isar/track.dart';
import 'package:shonenx/core/models/tracker/tracker_binding.dart';
import 'package:shonenx/core/models/tracker/tracker_type.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/main.dart';

/// Centralized repository for all local Isar operations on Track and Media.
class LocalMediaRepository {
  int _parseIntId(String idString) =>
      int.tryParse(idString) ?? (idString.isNotEmpty ? idString.hashCode : 0);

  // ─── Bindings ───

  Future<List<TrackerBinding>> getBindings(String mediaId) async {
    final track = await isar.tracks
        .filter()
        .mediaIdEqualTo(mediaId)
        .findFirst();
    return track?.bindings?.toList() ?? [];
  }

  Future<void> addBinding(
    String mediaId,
    TrackerType type,
    String remoteId,
  ) async {
    await isar.writeTxn(() async {
      final track =
          await isar.tracks.filter().mediaIdEqualTo(mediaId).findFirst() ??
          Track(mediaId: mediaId, status: TrackStatus.watching, progress: 0);

      track.bindings = [
        ...?track.bindings?.where((b) => b.type != type),
        TrackerBinding(type: type, remoteId: remoteId),
      ];
      await isar.tracks.put(track);
    });
  }

  Future<void> removeBinding(String mediaId, TrackerType type) async {
    await isar.writeTxn(() async {
      final track = await isar.tracks
          .filter()
          .mediaIdEqualTo(mediaId)
          .findFirst();
      if (track != null) {
        track.bindings =
            track.bindings?.where((b) => b.type != type).toList() ?? [];
        await isar.tracks.put(track);
      }
    });
  }

  // ─── Track CRUD ───

  Future<Track?> getTrack(String mediaId) async {
    return isar.tracks.filter().mediaIdEqualTo(mediaId).findFirst();
  }

  Future<void> saveTrack(Track track) async {
    await isar.writeTxn(() async {
      await isar.tracks.put(track);
    });
  }

  Future<List<Track>> getTracksByStatus(TrackStatus status) async {
    return isar.tracks.filter().statusEqualTo(status).findAll();
  }

  // ─── Entry (Track + Media combined) ───

  Future<UniversalMediaListEntry?> getEntry(String mediaId) async {
    final int id = _parseIntId(mediaId);
    if (id == 0) return null;

    final localMedia = await isar.medias.get(id);
    if (localMedia == null) return null;

    final track = await isar.tracks
        .filter()
        .mediaIdEqualTo(mediaId)
        .findFirst();
    if (track == null) return null;

    return UniversalMediaListEntry(
      id: track.id.toString(),
      media: mapMediaToUniversal(localMedia),
      status: track.status.name.toUpperCase(),
      score: (track.score ?? 0).toDouble(),
      progress: track.progress ?? 0,
      repeat: 0,
      isPrivate: false,
      notes: '',
    );
  }

  Future<void> saveEntry(
    UniversalMedia media, {
    required String status,
    required double score,
    required int progress,
    required int repeat,
    required String notes,
    required bool isPrivate,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    final int id = _parseIntId(media.id);
    if (id == 0) return;

    Media? localMedia = await isar.medias.get(id);
    localMedia ??= await ensureMediaExists(media);

    Track? track = await isar.tracks
        .filter()
        .mediaIdEqualTo(media.id)
        .findFirst();

    final trackStatus = mapStringToTrackStatus(status);

    await isar.writeTxn(() async {
      track ??= Track(mediaId: media.id, status: trackStatus);

      track!.status = trackStatus;
      track!.score = score.toInt();
      track!.progress = progress;
      track!.startedAt = startedAt?.millisecondsSinceEpoch;
      track!.completedAt = completedAt?.millisecondsSinceEpoch;
      track!.updatedAt = DateTime.now().millisecondsSinceEpoch;

      if (track!.bindings == null || track!.bindings!.isEmpty) {
        track!.bindings = [
          TrackerBinding(type: TrackerType.anilist, remoteId: media.id),
          if (media.idMal != null)
            TrackerBinding(type: TrackerType.mal, remoteId: media.idMal),
        ];
      }

      localMedia!.progress = progress;

      await isar.tracks.put(track!);
      await isar.medias.put(localMedia);
    });
  }

  Future<void> deleteEntry(String mediaId) async {
    final int id = _parseIntId(mediaId);
    if (id == 0) return;

    await isar.writeTxn(() async {
      await isar.tracks.filter().mediaIdEqualTo(mediaId).deleteAll();
      final media = await isar.medias.get(id);
      if (media != null) {
        media.status = Status.unknown;
        media.progress = 0;
        await isar.medias.put(media);
      }
    });
  }

  // ─── Favorites ───

  Future<bool> toggleFavorite(UniversalMedia media) async {
    final int id = _parseIntId(media.id);
    if (id == 0) return false;

    Media? localMedia = await isar.medias.get(id);
    localMedia ??= await ensureMediaExists(media);

    final newFavStatus = !(localMedia.favorite ?? false);
    await isar.writeTxn(() async {
      localMedia!.favorite = newFavStatus;
      await isar.medias.put(localMedia);
    });
    return newFavStatus;
  }

  Future<bool> isFavorite(String mediaId) async {
    final int id = _parseIntId(mediaId);
    if (id == 0) return false;
    final localMedia = await isar.medias.get(id);
    return localMedia?.favorite ?? false;
  }

  Future<List<Media>> getFavoriteMedias() async {
    return isar.medias.filter().favoriteEqualTo(true).findAll();
  }

  // ─── Media helpers ───

  Future<Media> ensureMediaExists(UniversalMedia media) async {
    final int id = _parseIntId(media.id);

    final existing = await isar.medias.get(id);
    if (existing != null) return existing;

    final newMedia = Media(
      id: id,
      source: 'LOCAL',
      genre: media.genres,
      imageUrl: media.coverImage.large ?? media.coverImage.medium ?? '',
      lang: '',
      link: media.siteUrl ?? '',
      name:
          media.title.english ??
          media.title.romaji ??
          media.title.native ??
          'Unknown',
      status: mapMediaStatus(media.status),
      description: media.description ?? '',
      itemType: ItemType.anime,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
    );

    await isar.writeTxn(() async {
      await isar.medias.put(newMedia);
    });

    return newMedia;
  }

  Future<Media?> getMedia(int id) async {
    return isar.medias.get(id);
  }

  Future<List<Media?>> getMedias(List<int> ids) async {
    return isar.medias.getAll(ids);
  }

  // ─── Mappers ───

  UniversalMedia mapMediaToUniversal(Media media) {
    return UniversalMedia(
      id: media.id.toString(),
      title: UniversalTitle(
        romaji: media.name,
        english: media.name,
        native: media.name,
      ),
      coverImage: UniversalCoverImage(
        large: media.imageUrl,
        medium: media.imageUrl,
      ),
      description: media.description,
      status: media.status.name.toUpperCase(),
      source: media.source,
    );
  }

  static TrackStatus mapStringToTrackStatus(String status) {
    switch (status.toUpperCase()) {
      case 'WATCHING':
      case 'CURRENT':
        return TrackStatus.watching;
      case 'COMPLETED':
        return TrackStatus.completed;
      case 'ON_HOLD':
      case 'PAUSED':
        return TrackStatus.onHold;
      case 'DROPPED':
        return TrackStatus.dropped;
      case 'PLANNING':
      case 'PLAN_TO_WATCH':
        return TrackStatus.planToWatch;
      case 'REPEATING':
      case 'REWATCHING':
        return TrackStatus.reWatching;
      default:
        return TrackStatus.planToWatch;
    }
  }

  static Status mapMediaStatus(String? status) {
    if (status == null) return Status.unknown;
    switch (status.toUpperCase()) {
      case 'FINISHED':
        return Status.completed;
      case 'RELEASING':
        return Status.ongoing;
      case 'CANCELLED':
        return Status.canceled;
      default:
        return Status.unknown;
    }
  }
}

final localMediaRepoProvider = Provider<LocalMediaRepository>((ref) {
  return LocalMediaRepository();
});
