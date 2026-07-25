import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

extension MediaTypeSourceResolution on MediaType {
  FutureProvider<List<SourceInfo>> get availableSourcesProvider {
    if (this == MediaType.ANIME ||
        this == MediaType.MOVIE ||
        this == MediaType.TV) {
      return availableAnimeSourcesProvider;
    } else if (this == MediaType.NOVEL) {
      return availableNovelSourcesProvider;
    } else {
      return availableMangaSourcesProvider;
    }
  }

  bool get usesAnimeSources {
    return this == MediaType.ANIME ||
        this == MediaType.MOVIE ||
        this == MediaType.TV;
  }
}
