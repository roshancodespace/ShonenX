import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anilist/media.dart' as anilist;
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core_new/eval/model/m_manga.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/navigation.dart';

class DemoScreen extends ConsumerStatefulWidget {
  const DemoScreen({super.key});

  @override
  ConsumerState<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends ConsumerState<DemoScreen> {
  late List<MManga> data = [];
  bool loading = false;
  Future<void> search(String query, WidgetRef r) async {
    setState(() {
      loading = true;
    });
    final searchedData = await r.read(sourceProvider.notifier).search(query);
    setState(() {
      data = searchedData.list;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to demo!'),
      ),
      body: Column(
        children: [
          SearchBar(
            hintText: 'Search for anime!',
            onSubmitted: (value) => search(value, ref),
          ),
          !loading
              ? Expanded(
                  child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 1.2),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final anime = data[index];
                    return AnimatedAnimeCard(
                      anime: anilist.Media(
                          title: anilist.Title(
                            english: anime.name.toString(),
                            romaji: anime.name.toString(),
                          ),
                          coverImage: anilist.CoverImage(
                              large: anime.imageUrl.toString(),
                              medium: anime.imageUrl.toString()),
                          format: anime.author),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DemoDetail(
                                url: anime.link!,
                              ),
                            ));
                      },
                      tag: anime.name.toString(),
                    );
                  },
                ))
              : Center(child: CircularProgressIndicator())
        ],
      ),
    );
  }
}

class DemoDetail extends ConsumerStatefulWidget {
  final String url;
  const DemoDetail({super.key, required this.url});

  @override
  ConsumerState<DemoDetail> createState() => _DemoDetailState();
}

class _DemoDetailState extends ConsumerState<DemoDetail> {
  MManga? media;
  @override
  void initState() {
    super.initState();
    fetch();
  }

  void fetch() async {
    try {
      final data =
          await ref.read(sourceProvider.notifier).getDetails(widget.url);
      setState(() {
        media = data;
        AppLogger.d(data?.toJson());
      });
    } catch (err) {
      AppLogger.e(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Demo details"),
      ),
      body: ListView(
          children: media?.chapters
                  ?.map((chapter) => ListTile(
                        onTap: () async {
                          if (chapter.url == null) return;
                          final sources = await ref
                              .read(sourceProvider.notifier)
                              .getSources(chapter.url!);
                          for (var s in sources) {
                            for (var ss in s?.subtitles ?? []) {
                              AppLogger.w(ss.file);
                              AppLogger.w(ss.label);
                            }
                          }
                          if (!context.mounted) return;
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return BottomSheet(
                                onClosing: () => Navigator.pop(context),
                                builder: (context) {
                                  return Container(
                                    color: Colors.black,
                                    child: ListView(
                                      children: sources
                                          .map((s) => ListTile(
                                                title: Text('${s?.quality}'),
                                                subtitle: Text('${s?.url}'),
                                                onTap: () {
                                                  navigateToWatch(
                                                      context: context,
                                                      ref: ref,
                                                      animeId: 'Niggesh',
                                                      animeName:
                                                          '${media?.name}',
                                                      episodes: media?.chapters
                                                              ?.map((ch) => EpisodeDataModel(
                                                                  title: ch.name
                                                                      ?.split(
                                                                          ':')
                                                                      .last
                                                                      .trim(),
                                                                  url: ch.url,
                                                                  number: int.parse(ch
                                                                          .name
                                                                          ?.split(
                                                                              ':')
                                                                          .first
                                                                          .split(
                                                                              ' ')
                                                                          .last
                                                                          .trim() ??
                                                                      '')))
                                                              .toList() ??
                                                          []);
                                                },
                                              ))
                                          .toList(),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        title: Text('${chapter.name}'),
                        subtitle: Text('${chapter.url}'),
                      ))
                  .toList()
                  .reversed
                  .toList() ??
              []),
    );
  }
}
