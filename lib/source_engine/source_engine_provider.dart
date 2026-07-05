import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/source_engine/adapters/anime_source_adapter.dart';
import 'package:shonenx/source_engine/adapters/manga_source_adapter.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'package:shonenx/source_engine/providers/manga_source.dart';
import 'package:shonenx/source_engine/providers/inbuilt_sources_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:get/get.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';

import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';

final metadataSourceProvider = Provider<RemoteTracker>((ref) {
  final prefs = ref.watch(discoveryPrefsProvider);
  final targetTrackerId = prefs.metadataTrackerId;

  if (targetTrackerId != null) {
    final targetType = TrackerType.tryFromId(targetTrackerId);
    if (targetType != null) {
      final trackers = ref.watch(availableTrackersProvider);
      try {
        final targetTracker = trackers.firstWhere((t) => t.type == targetType);
        if (targetTracker is RemoteTracker) {
          return targetTracker;
        }
      } catch (_) {}
    }
  }

  // Fallback to primary
  final primary = ref.watch(primaryTrackerProvider);
  if (primary is RemoteTracker) {
    return primary;
  }

  final trackers = ref.watch(availableTrackersProvider);
  return trackers.firstWhere((t) => t is RemoteTracker) as RemoteTracker;
}, name: 'metadataSourceProvider');

final animeSourceProvider = Provider.family<AnimeSource, SourceInfo>((
  ref,
  info,
) {
  if (info.type == SourceType.inbuilt) {
    return ref
        .read(inbuiltAnimeSourcesProvider)
        .firstWhere((s) => s.sourceInfo.id == info.id);
  }

  final bridgeManager = Get.find<bridge.ExtensionManager>();
  final ext = bridgeManager.installedAnimeExtensions.firstWhere(
    (e) => (e.name ?? "Unknown") == info.name || (e.id ?? "") == info.id,
    orElse: () => throw StateError('Extension "${info.name}" not found'),
  );

  return AnimeSourceAdapter(
    sourceInfo: SourceInfo(
      id: ext.id!,
      name: ext.name!,
      type: SourceType.extension,
      mediaType: MediaType.ANIME,
      iconUrl: ext.iconUrl,
    ),
    source: ext,
  );
}, name: 'animeSourceProvider');

final mangaSourceProvider = Provider.family<MangaSource, SourceInfo>((
  ref,
  info,
) {
  if (info.type == SourceType.inbuilt) {
    return ref
        .read(inbuiltMangaSourcesProvider)
        .firstWhere((s) => s.sourceInfo.id == info.id);
  }

  final bridgeManager = Get.find<bridge.ExtensionManager>();
  final ext = bridgeManager.installedMangaExtensions.firstWhere(
    (e) => (e.name ?? "Unknown") == info.name || (e.id ?? "") == info.id,
    orElse: () => bridgeManager.installedNovelExtensions.firstWhere(
      (e) => (e.name ?? "Unknown") == info.name || (e.id ?? "") == info.id,
      orElse: () => throw StateError('Extension "${info.name}" not found'),
    ),
  );

  return MangaSourceAdapter(
    sourceInfo: SourceInfo(
      id: ext.id!,
      name: ext.name!,
      type: SourceType.extension,
      mediaType: MediaType.MANGA,
      iconUrl: ext.iconUrl,
      baseUrl: ext.baseUrl,
    ),
    source: ext,
  );
}, name: 'mangaSourceProvider');
