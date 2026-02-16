import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart' hide Track;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/data/isar/manga.dart';
import 'package:shonenx/data/isar/track.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';

class LocalTrackerNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Toggles the favorite status of a media item in the local database.
  Future<bool> toggleFavorite(UniversalMedia media) async {
    final int id = int.tryParse(media.id) ?? 0;
    if (id == 0) return false;

    Manga? manga = await isar.mangas.get(id);

    // If manga doesn't exist, create it locally
    manga ??= await _ensureMangaExists(media);

    final newFavStatus = !(manga.favorite ?? false);

    await isar.writeTxn(() async {
      manga!.favorite = newFavStatus;
      await isar.mangas.put(manga);
    });

    // Refresh handled by watchers in WatchlistNotifier
    // ref.read(watchlistProvider.notifier).fetchListForStatus('favorites', force: true);

    return newFavStatus;
  }

  /// Checks if a media item is marked as favorite locally.
  Future<bool> isFavorite(String mediaId) async {
    final int id = int.tryParse(mediaId) ?? 0;
    if (id == 0) return false;

    final manga = await isar.mangas.get(id);
    return manga?.favorite ?? false;
  }

  /// Fetches the local list entry (Track) for a media item.
  Future<UniversalMediaListEntry?> getEntry(String mediaId) async {
    final int id = int.tryParse(mediaId) ?? 0;
    if (id == 0) return null;

    final manga = await isar.mangas.get(id);
    if (manga == null) return null;

    final track = await isar.tracks.filter().mangaIdEqualTo(id).findFirst();
    if (track == null) return null;

    return UniversalMediaListEntry(
      id: track.id.toString(),
      media: _mapMangaToUniversal(manga),
      status: track.status.name.toUpperCase(),
      score: (track.score ?? 0).toDouble(),
      progress: track.lastChapterRead ?? 0,
      repeat: 0,
      isPrivate: false,
      notes: '',
    );
  }

  /// Saves or updates a tracking entry locally.
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
    final int id = int.tryParse(media.id) ?? 0;
    if (id == 0) return;

    Manga? manga = await isar.mangas.get(id);
    manga ??= await _ensureMangaExists(media);

    Track? track = await isar.tracks.filter().mangaIdEqualTo(id).findFirst();

    final trackStatus = _mapStatus(status);

    await isar.writeTxn(() async {
      // Create track if not exists
      track ??= Track(
        mangaId: id,
        mediaId: id,
        status: trackStatus, // Will be updated below
      );

      track!.status = trackStatus;
      track!.score = score.toInt();
      track!.lastChapterRead = progress;
      track!.startedReadingDate = startedAt?.millisecondsSinceEpoch;
      track!.finishedReadingDate = completedAt?.millisecondsSinceEpoch;
      track!.updatedAt = DateTime.now().millisecondsSinceEpoch;

      manga!.lastRead = progress;

      await isar.tracks.put(track!);
      await isar.mangas.put(manga);
    });
  }

  /// Helper to create a Manga object from UniversalMedia if it doesn't exist.
  Future<Manga> _ensureMangaExists(UniversalMedia media) async {
    final int id = int.tryParse(media.id) ?? 0;

    // Check if it exists again just in case
    final existing = await isar.mangas.get(id);
    if (existing != null) return existing;

    final newManga = Manga(
      id: id,
      source: 'LOCAL', // Indicates manually added
      author: media.staff.isNotEmpty ? media.staff.first.name?.full : 'Unknown',
      artist: '',
      genre: media.genres,
      imageUrl: media.coverImage.large ?? media.coverImage.medium ?? '',
      lang: '',
      link: media.siteUrl ?? '',
      name:
          media.title.english ??
          media.title.romaji ??
          media.title.native ??
          'Unknown',
      status: _mapMediaStatus(media.status),
      description: media.description ?? '',
      itemType: ItemType.anime,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
    );

    await isar.writeTxn(() async {
      await isar.mangas.put(newManga);
    });

    return newManga;
  }

  Status _mapMediaStatus(String? status) {
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

  TrackStatus _mapStatus(String status) {
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

  UniversalMedia _mapMangaToUniversal(Manga manga) {
    return UniversalMedia(
      id: manga.id.toString(),
      title: UniversalTitle(
        romaji: manga.name,
        english: manga.name,
        native: manga.name,
      ),
      coverImage: UniversalCoverImage(
        large: manga.imageUrl,
        medium: manga.imageUrl,
      ),
      description: manga.description,
      status: manga.status.name.toUpperCase(),
      source: manga.source,
    );
  }

  Future<void> deleteEntry(String mediaId) async {
    final int id = int.tryParse(mediaId) ?? 0;
    if (id == 0) return;

    await isar.writeTxn(() async {
      await isar.tracks.filter().mangaIdEqualTo(id).deleteAll();

      final manga = await isar.mangas.get(id);
      if (manga != null) {
        manga.status = Status.unknown;
        manga.lastRead = 0;
        await isar.mangas.put(manga);
      }
    });
  }
}

final localTrackerProvider = NotifierProvider<LocalTrackerNotifier, void>(
  LocalTrackerNotifier.new,
);
