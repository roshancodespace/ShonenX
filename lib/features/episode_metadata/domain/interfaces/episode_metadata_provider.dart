import 'package:shonenx/features/episode_metadata/domain/models/episode_metadata.dart';
import 'package:shonenx/shared/models/unified_media.dart';

abstract class EpisodeMetadataProvider {
  String get id;
  String get name;

  Future<String?> resolveId({required UnifiedMedia media});

  Future<List<EpisodeMetadata>> fetchEpisodes({
    required UnifiedMedia media,
    void Function(String message)? onProgress,
  });
}
