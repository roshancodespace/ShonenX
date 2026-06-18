import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/source_engine/adapters/anime_extension_adapter.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'package:shonenx/source_engine/providers/manga_source.dart';
import 'package:shonenx/source_engine/providers/inbuilt_sources_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';

final metadataSourceProvider = Provider<RemoteTracker>((ref) {
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

  final manager = ref.read(extensionManagerProvider);
  final ext = manager
      .getInstalledRx(bridge.ItemType.anime)
      .value
      .firstWhere(
        (e) => (e.name ?? "Unknown") == info.name,
        orElse: () => throw StateError('Extension "${info.name}" not found'),
      );

  return AnimeExtensionAdapter(
    sourceInfo: SourceInfo(
      id: ext.id!,
      name: ext.name!,
      type: SourceType.extension,
      mediaType: MediaType.ANIME,
      iconUrl: ext.iconUrl,
    ),
    methods: AnimeBridgeMethods(
      search: ext.methods.search,
      getDetail: ext.methods.getDetail,
      getVideoList: ext.methods.getVideoList,
      getPopular: ext.methods.getPopular,
      getSettingsSchema: ext.methods.getPreference,
    ),
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

  throw UnimplementedError('Manga extension adapter not implemented yet');
}, name: 'mangaSourceProvider');
