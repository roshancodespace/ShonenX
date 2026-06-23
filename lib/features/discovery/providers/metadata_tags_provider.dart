import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

class MetadataTagsState {
  final List<String> genres;
  final List<String> tags;

  const MetadataTagsState({this.genres = const [], this.tags = const []});
}

final metadataTagsProvider = FutureProvider.autoDispose<MetadataTagsState>((ref) async {
  final source = ref.watch(metadataSourceProvider);

  final genres = await source.fetchGenres();
  final tags = await source.fetchTags();

  return MetadataTagsState(genres: genres, tags: tags);
});
