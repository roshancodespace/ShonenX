import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/episode_metadata/services/anizip_metadata_client.dart';
import 'package:shonenx/features/episode_metadata/services/episode_metadata_service.dart';
import 'package:shonenx/features/episode_metadata/services/jikan_metadata_client.dart';
import 'package:shonenx/features/episode_metadata/services/kitsu_metadata_client.dart';
import 'package:shonenx/features/episode_metadata/services/tenrai_metadata_client.dart';

final anizipMetadataProvider = Provider<AniZipEpisodeMetadataClient>((ref) {
  final http = ref.watch(httpClientProvider);
  return AniZipEpisodeMetadataClient(http: http);
});

final tenraiMetadataProvider = Provider<TenraiEpisodeMetadataClient>((ref) {
  final http = ref.watch(httpClientProvider);
  return TenraiEpisodeMetadataClient(http: http);
});

final kitsuMetadataProvider = Provider<KitsuEpisodeMetadataClient>((ref) {
  final http = ref.watch(httpClientProvider);
  return KitsuEpisodeMetadataClient(http: http);
});

final jikanMetadataProvider = Provider<JikanEpisodeMetadataClient>((ref) {
  final http = ref.watch(httpClientProvider);
  return JikanEpisodeMetadataClient(http: http);
});

final episodeMetadataServiceProvider = Provider<EpisodeMetadataService>((ref) {
  final anizip = ref.watch(anizipMetadataProvider);
  final tenrai = ref.watch(tenraiMetadataProvider);
  final kitsu = ref.watch(kitsuMetadataProvider);
  final jikan = ref.watch(jikanMetadataProvider);
  final service = EpisodeMetadataService(
    anizip: anizip,
    tenrai: tenrai,
    kitsu: kitsu,
    jikan: jikan,
  );
  ref.onDispose(service.dispose);
  return service;
});

final episodeMetadataProgressProvider = StreamProvider<String>((ref) {
  final service = ref.watch(episodeMetadataServiceProvider);
  return service.progressStream;
});
