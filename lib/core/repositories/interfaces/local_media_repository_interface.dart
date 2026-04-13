import 'package:shonenx/core/models/tracker/tracker_binding.dart';
import 'package:shonenx/core/models/tracker/tracker_type.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/data/isar/media.dart' as db;
import 'package:shonenx/data/isar/track.dart' as db;

abstract class LocalMediaRepositoryInterface {
  Future<List<TrackerBinding>> getBindings(String mediaId);
  Future<void> addBinding(String mediaId, TrackerType type, String remoteId);
  Future<void> removeBinding(String mediaId, TrackerType type);

  Future<db.Track?> getTrack(String mediaId);
  Future<void> saveTrack(db.Track track);
  Future<List<db.Track>> getTracksByStatus(db.TrackStatus status);

  Future<UniversalMediaListEntry?> getEntry(String mediaId);
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
  });
  Future<void> deleteEntry(String mediaId);

  Future<bool> toggleFavorite(UniversalMedia media);
  Future<bool> isFavorite(String mediaId);
  Future<List<db.Media>> getFavoriteMedias();

  Future<db.Media> ensureMediaExists(UniversalMedia media);
  Future<db.Media?> getMedia(int id);
  Future<List<db.Media?>> getMedias(List<int> ids);

  UniversalMedia mapMediaToUniversal(db.Media media);
}
