import 'package:isar_community/isar.dart';

part 'Settings.g.dart';

@collection
@Name("BridgeSettings")
class BridgeSettings {
  Id? id;
  String? currentManager;
  List<String> sortedAnimeExtensions;
  List<String> sortedMangaExtensions;
  List<String> sortedNovelExtensions;
  List<String> aniyomiAnimeExtensions;
  List<String> aniyomiMangaExtensions;

  List<String> mangayomiAnimeExtensions;
  List<String> mangayomiMangaExtensions;
  List<String> mangayomiNovelExtensions;

  BridgeSettings({
    this.currentManager,
    this.sortedAnimeExtensions = const [],
    this.sortedMangaExtensions = const [],
    this.sortedNovelExtensions = const [],
    this.aniyomiAnimeExtensions = const [],
    this.aniyomiMangaExtensions = const [],
    this.mangayomiAnimeExtensions = const [],
    this.mangayomiMangaExtensions = const [],
    this.mangayomiNovelExtensions = const [],
  });
}
