import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/source_engine/source_registry.dart';

extension SourceInvalidation on Ref {
  void invalidateAllSources() {
    invalidate(extensionManagerProvider);
    invalidate(availableAnimeSourcesProvider);
    invalidate(availableMangaSourcesProvider);
    invalidate(availableNovelSourcesProvider);
    invalidate(allAvailableSourcesProvider);
  }
}

extension WidgetSourceInvalidation on WidgetRef {
  void invalidateAllSources() {
    invalidate(extensionManagerProvider);
    invalidate(availableAnimeSourcesProvider);
    invalidate(availableMangaSourcesProvider);
    invalidate(availableNovelSourcesProvider);
    invalidate(allAvailableSourcesProvider);
  }
}
