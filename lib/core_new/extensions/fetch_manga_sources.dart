import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core_new/extensions/fetch_source_list.dart';
import 'package:shonenx/core_new/models/manga.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';

part 'fetch_manga_sources.g.dart';

@riverpod
Future fetchMangaSourcesList(FetchMangaSourcesListRef ref,
    {int? id, required reFresh}) async {
  var repo = ref.watch(sourceProvider).activeMangaRepo;
  await fetchSourcesList(
    sourcesIndexUrl: repo,
    id: id,
    ref: ref,
    itemType: ItemType.manga,
  );
}
