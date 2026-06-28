import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

final trackerLinkProvider =
    AsyncNotifierProvider.family<
      TrackerLinkNotifier,
      Map<TrackerType, TrackerMapping>,
      String
    >(TrackerLinkNotifier.new);

class TrackerLinkNotifier
    extends AsyncNotifier<Map<TrackerType, TrackerMapping>> {
  late final _isar = ref.read(databaseProvider);

  TrackerLinkNotifier(this.mediaId);

  final String mediaId;

  @override
  Future<Map<TrackerType, TrackerMapping>> build() async {
    final linkDoc = await _isar.isarTrackerLinks.getByPrimaryMediaId(mediaId);

    if (linkDoc == null) return {};

    final Map<TrackerType, TrackerMapping> currentLinks = {};
    for (final mapping in linkDoc.mappings) {
      if (mapping.trackerId != null && mapping.trackingId != null) {
        currentLinks[TrackerType.fromId(mapping.trackerId!)] = mapping;
      }
    }
    return currentLinks;
  }

  void saveLink(TrackerType trackerType, TrackerMapping trackerMapping) {
    final updatedLinks = Map<TrackerType, TrackerMapping>.from(
      state.value ?? {},
    );
    updatedLinks[trackerType] = trackerMapping;

    final newMappings = updatedLinks.entries
        .map(
          (e) => TrackerMapping()
            ..trackerId = e.value.trackerId
            ..trackingTitle = e.value.trackingTitle
            ..trackingId = e.value.trackingId,
        )
        .toList();

    final linkDoc = IsarTrackerLink()
      ..primaryMediaId = mediaId
      ..mappings = newMappings;

    _isar.writeTxnSync(() {
      _isar.isarTrackerLinks.putSync(linkDoc);
    });

    state = AsyncData(updatedLinks);
  }

  void removeLink(TrackerType trackerType) {
    final updatedLinks = Map<TrackerType, TrackerMapping>.from(
      state.value ?? {},
    );
    updatedLinks.remove(trackerType);

    final newMappings = updatedLinks.entries
        .map(
          (e) => TrackerMapping()
            ..trackerId = e.value.trackerId
            ..trackingTitle = e.value.trackingTitle
            ..trackingId = e.value.trackingId,
        )
        .toList();

    final linkDoc = IsarTrackerLink()
      ..primaryMediaId = mediaId
      ..mappings = newMappings;

    _isar.writeTxnSync(() {
      _isar.isarTrackerLinks.putSync(linkDoc);
    });

    state = AsyncData(updatedLinks);
  }
}
