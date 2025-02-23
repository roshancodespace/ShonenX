import 'dart:developer';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/provider.dart';

Future<void> providerAnimeMatchSearch({
  Function? beforeSearchCallback,
  Function? afterSearchCallback,
  required BuildContext context,
  required WidgetRef ref,
  required Media animeMedia,
  required AnimeWatchProgressBox animeWatchProgressBox,
}) async {
  if (beforeSearchCallback != null) beforeSearchCallback();

  try {
    final animeProvider = getAnimeProvider(ref);
    final title = animeMedia.title?.english ??
        animeMedia.title?.romaji ??
        animeMedia.title?.native;

    final response = await animeProvider?.getSearch(
      title!.replaceAll(' ', '+'),
      animeMedia.format,
      1,
    );

    if (!context.mounted || response == null) return;

    final matchedResults = response.results
        .map((result) {
          final similarity = calculateSimilarity(
            result.name?.toLowerCase(),
            title?.toLowerCase(),
          );
          return (result, similarity);
        })
        .where((pair) => pair.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    if (!context.mounted) return;

    if (matchedResults.isEmpty && response.results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'Anime Not Found',
          message: 'We couldn\'t locate the anime with the selected provider.',
          contentType: ContentType.failure,
        ),
      ));
      return;
    }

    // Direct navigation for high confidence matches
    if (matchedResults.isNotEmpty && matchedResults.first.$2 >= 0.8) {
      final bestMatch = matchedResults.first.$1;
      log("Best match found: ${bestMatch.id}");
      context.push('/watch/${bestMatch.id}?animeName=${bestMatch.name}',
          extra: animeMedia);
      return;
    }

    // Show selection dialog for multiple matches
    final results = matchedResults.isEmpty
        ? response.results
        : matchedResults.map((r) => r.$1).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        'Select Anime',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          final continueWatchingEntry = animeWatchProgressBox
                              .getMostRecentEpisodeProgressByAnimeId(
                                  animeMedia.id!);
                          if (continueWatchingEntry != null) {
                            context.push(
                                '/watch/${result.id}?animeName=${result.name}&episode=${continueWatchingEntry.episodeNumber}&startAt=${continueWatchingEntry.progressInSeconds}',
                                extra: animeMedia);
                          } else {
                            context.push(
                                '/watch/${result.id}?animeName=${result.name}',
                                extra: animeMedia);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Thumbnail
                              if (result.poster != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: result.poster!,
                                    width: 50,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 50,
                                      height: 70,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 50,
                                      height: 70,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Icon(Icons.broken_image,
                                          size: 20),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              // Title and details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result.name ?? 'Unknown',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (result.releaseDate != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        result.releaseDate!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'Error',
          message: 'Failed to load anime details. Please try again.',
          contentType: ContentType.failure,
        ),
      ));
    }
  } finally {
    if (afterSearchCallback != null) afterSearchCallback();
  }
}
