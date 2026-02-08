// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shonenx/core/models/universal/universal_media.dart';
// import 'package:shonenx/core/models/anime/episode_model.dart';
// import 'package:shonenx/core/utils/app_logger.dart';
// import 'package:shonenx/core_mangayomi/eval/model/m_manga.dart';
// import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
// import 'package:shonenx/features/settings/view_model/source_notifier.dart';
// import 'package:shonenx/helpers/navigation.dart';

// /// Helper: Extract first consecutive number from string, or null
// int? extractNumber(String? text) =>
//     int.tryParse(RegExp(r'\d+').firstMatch(text ?? '')?.group(0) ?? '');

// class DemoScreen extends ConsumerStatefulWidget {
//   const DemoScreen({super.key});

//   @override
//   ConsumerState<DemoScreen> createState() => _DemoScreenState();
// }

// class _DemoScreenState extends ConsumerState<DemoScreen> {
//   List<MManga> data = [];
//   bool loading = false;
//   final TextEditingController searchController = TextEditingController();

//   Future<void> search(String query) async {
//     setState(() => loading = true);
//     try {
//       final result = await ref.read(sourceProvider.notifier).search(query);
//       setState(() => data = result.list);
//     } catch (e) {
//       AppLogger.e(e);
//     } finally {
//       setState(() => loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Welcome to demo!')),
//       body: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           children: [
//             // Search bar
//             Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 2,
//               child: TextField(
//                 controller: searchController,
//                 decoration: const InputDecoration(
//                   hintText: 'Search for anime!',
//                   border: InputBorder.none,
//                   contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                 ),
//                 onSubmitted: search,
//               ),
//             ),
//             const SizedBox(height: 12),
//             // Loading / Grid
//             loading
//                 ? const Expanded(
//                     child: Center(child: CircularProgressIndicator()),
//                   )
//                 : data.isEmpty
//                 ? const Expanded(child: Center(child: Text('No results found')))
//                 : Expanded(
//                     child: GridView.builder(
//                       gridDelegate:
//                           const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 2,
//                             childAspectRatio: 0.7,
//                             crossAxisSpacing: 12,
//                             mainAxisSpacing: 12,
//                           ),
//                       itemCount: data.length,
//                       itemBuilder: (context, index) {
//                         final anime = data[index];
//                         return GestureDetector(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => DemoDetail(url: anime.link!),
//                               ),
//                             );
//                           },
//                           child: AnimatedAnimeCard(
//                             anime: UniversalMedia(
//                               id: 'demo',
//                               title: UniversalTitle(
//                                 english: anime.name ?? '',
//                                 romaji: anime.name ?? '',
//                               ),
//                               coverImage: UniversalCoverImage(
//                                 large: anime.imageUrl ?? '',
//                                 medium: anime.imageUrl ?? '',
//                               ),
//                               format: anime.author,
//                             ),
//                             tag: anime.name ?? '',
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class DemoDetail extends ConsumerStatefulWidget {
//   final String url;
//   const DemoDetail({super.key, required this.url});

//   @override
//   ConsumerState<DemoDetail> createState() => _DemoDetailState();
// }

// class _DemoDetailState extends ConsumerState<DemoDetail> {
//   MManga? media;
//   bool loading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetch();
//   }

//   void fetch() async {
//     try {
//       final data = await ref
//           .read(sourceProvider.notifier)
//           .getDetails(widget.url);
//       setState(() => media = data);
//       AppLogger.d(data?.toJson());
//     } catch (err) {
//       AppLogger.e(err);
//     } finally {
//       setState(() => loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (media == null) {
//       return const Scaffold(
//         body: Center(child: Text("Failed to load details")),
//       );
//     }

//     final chapters = media!.chapters?.reversed.toList() ?? [];

//     return Scaffold(
//       appBar: AppBar(title: Text(media!.name ?? "Details")),
//       body: ListView.builder(
//         itemCount: chapters.length,
//         itemBuilder: (context, i) {
//           final ch = chapters[i];
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: ListTile(
//               title: Text(ch.name ?? ''),
//               subtitle: Text(ch.url ?? ''),
//               onTap: () async {
//                 if (ch.url == null) return;
//                 final sources = await ref
//                     .read(sourceProvider.notifier)
//                     .getSources(ch.url!, "", "", "", "sub");
//                 if (!context.mounted) return;

//                 showModalBottomSheet(
//                   context: context,
//                   builder: (_) => Container(
//                     color: Colors.black,
//                     child: ListView(
//                       children: sources
//                           .map(
//                             (s) => ListTile(
//                               title: Text(s?.quality ?? ''),
//                               subtitle: Text(s?.url ?? ''),
//                               onTap: () {
//                                 final episodes = media!.chapters!
//                                     .map(
//                                       (c) => EpisodeDataModel(
//                                         title: c.name,
//                                         url: c.url,
//                                         number: extractNumber(c.name),
//                                       ),
//                                     )
//                                     .toList();

//                                 navigateToWatch(
//                                   animeFormat: 'DEMO',
//                                   animeCover: media?.imageUrl ?? '',
//                                   context: context,
//                                   ref: ref,
//                                   mediaId: 'demo',
//                                   animeId: media!.name,
//                                   animeName: media!.name ?? 'demo',
//                                   episodes: episodes,
//                                   currentEpisode: 1,
//                                 );
//                               },
//                             ),
//                           )
//                           .toList(),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
