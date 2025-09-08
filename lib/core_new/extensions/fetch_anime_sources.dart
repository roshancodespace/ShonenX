import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core_new/extensions/fetch_source_list.dart';
import 'package:shonenx/core_new/models/manga.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';

part 'fetch_anime_sources.g.dart';

@riverpod
Future fetchAnimeSourcesList(FetchAnimeSourcesListRef ref,
    {int? id, required bool reFresh}) async {
  var repo = ref.watch(sourceProvider).activeAnimeRepo;
    await fetchSourcesList(
      sourcesIndexUrl: repo,
      id: id,
      ref: ref,
      itemType: ItemType.anime,
    );
  
}
