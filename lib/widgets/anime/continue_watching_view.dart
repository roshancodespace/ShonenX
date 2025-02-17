import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive/hive.dart';
import 'package:shonenx/data/hive/boxes/continue_watching_box.dart';
import 'package:shonenx/data/hive/models/continue_watching_model.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/provider.dart';

class ContinueWatchingView extends StatelessWidget {
  final ContinueWatchingBox continueWatchingBox;
  const ContinueWatchingView({super.key, required this.continueWatchingBox});

  @override
  Widget build(BuildContext context) {
    if (continueWatchingBox.getAllEntries().isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.play_circle,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue Watching',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  // Navigate to a full list of continue watching items
                },
                icon: const Icon(Iconsax.arrow_right_3, size: 24),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ValueListenableBuilder<Box<ContinueWatchingEntry>>(
            valueListenable: continueWatchingBox.boxValueListenable,
            builder: (context, box, _) {
              final entries = box.values.toList();
              if (entries.isEmpty) {
                return _EmptyWatchingState();
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _ContinueWatchingCard(
                      continueWatchingEntry: entries[index],
                      index: index,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyWatchingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.video_circle,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No shows in progress',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              // Navigate to browse shows
            },
            icon: const Icon(Iconsax.discover),
            label: const Text('Browse Shows'),
          ),
        ],
      ),
    );
  }
}

final loadingProvider = StateProvider.family<bool, int>((ref, index) => false);

class _ContinueWatchingCard extends ConsumerWidget {
  final ContinueWatchingEntry continueWatchingEntry;
  final int index;

  const _ContinueWatchingCard({
    required this.continueWatchingEntry,
    required this.index,
  });

  String _formatRemainingTime(int current, int total) {
    final remaining = (total - current) ~/ 60;
    return '$remaining min left';
  }

  double _calculateProgress() {
    if (continueWatchingEntry.durationInSeconds == 0) return 0;
    return (continueWatchingEntry.progressInSeconds ?? 0) /
        (continueWatchingEntry.durationInSeconds ?? 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _calculateProgress();
    final isLoading = ref.watch(loadingProvider(index));

    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Thumbnail with gradient overlay
              Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Image.memory(
                    base64Decode(continueWatchingEntry.episodeThumbnail!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return CachedNetworkImage(
                        imageUrl: continueWatchingEntry.animeCover!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.tertiary,
                            colorScheme.primary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Play button with ripple effect
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      ref.read(loadingProvider(index).notifier).state = true;
                      final animeProvider = getAnimeProvider(ref);
                      final title = continueWatchingEntry.animeTitle;

                      final response = await animeProvider?.getSearch(
                        title!.replaceAll(' ', '+'),
                        continueWatchingEntry.animeFormat,
                        1,
                      );

                      if (response == null) {
                        ref.read(loadingProvider(index).notifier).state = false;
                        return;
                      }

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

                      if (matchedResults.isEmpty &&
                          response.results.isEmpty &&
                          context.mounted) {
                        ref.read(loadingProvider(index).notifier).state = false;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          content: AwesomeSnackbarContent(
                            title: 'Anime Not Found',
                            message:
                                'We couldn\'t locate the anime with the selected provider.',
                            contentType: ContentType.failure,
                          ),
                        ));
                        return;
                      }

                      // Direct navigation for high confidence matches
                      if (matchedResults.isNotEmpty &&
                          matchedResults.first.$2 >= 0.8 &&
                          context.mounted) {
                        final bestMatch = matchedResults.first.$1;
                        ref.read(loadingProvider(index).notifier).state = false;
                        context.push(
                          '/watch/${bestMatch.id}?animeName=${bestMatch.name}&episode=${continueWatchingEntry.episodeNumber}&startAt=${continueWatchingEntry.progressInSeconds}',
                          extra: anime_media.Media(
                            id: continueWatchingEntry.animeId,
                            title: anime_media.Title(
                                english: title, romaji: title!),
                            format: continueWatchingEntry.animeFormat ??
                                bestMatch.type,
                            coverImage: anime_media.CoverImage(
                                large: continueWatchingEntry.animeCover!,
                                medium: continueWatchingEntry.animeCover!),
                            episodes: continueWatchingEntry.episodeNumber,
                            duration: continueWatchingEntry.durationInSeconds,
                          ),
                        );
                        return;
                      }

                      // Show selection dialog for multiple matches
                      final results = matchedResults.isEmpty
                          ? response.results
                          : matchedResults.map((r) => r.$1).toList();
                      if (context.mounted) {
                        ref.read(loadingProvider(index).notifier).state = false;
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                  maxHeight: 300,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 8, 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Select Anime',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Flexible(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        itemCount: results.length,
                                        itemBuilder: (context, index) {
                                          final result = results[index];
                                          return InkWell(
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              context.push(
                                                '/watch/${result.id}?animeName=${result.name}&episode=${continueWatchingEntry.episodeNumber}&startAt=${continueWatchingEntry.progressInSeconds}',
                                                extra: anime_media.Media(
                                                  id: continueWatchingEntry
                                                      .animeId,
                                                  title: anime_media.Title(
                                                      english: title,
                                                      romaji: title!),
                                                  format: continueWatchingEntry
                                                      .animeFormat,
                                                  coverImage: anime_media.CoverImage(
                                                      large:
                                                          continueWatchingEntry
                                                              .animeCover!,
                                                      medium:
                                                          continueWatchingEntry
                                                              .animeCover!),
                                                  episodes:
                                                      continueWatchingEntry
                                                          .episodeNumber,
                                                  duration:
                                                      continueWatchingEntry
                                                          .durationInSeconds,
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              child: Row(
                                                children: [
                                                  // Thumbnail
                                                  if (result.poster != null)
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: CachedNetworkImage(
                                                        imageUrl:
                                                            result.poster!,
                                                        width: 50,
                                                        height: 70,
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (context, url) =>
                                                                Container(
                                                          width: 50,
                                                          height: 70,
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .surfaceContainerHighest,
                                                          child: const Center(
                                                            child: SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Container(
                                                          width: 50,
                                                          height: 70,
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .surfaceContainerHighest,
                                                          child: const Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 20),
                                                        ),
                                                      ),
                                                    ),
                                                  const SizedBox(width: 12),
                                                  // Title and details
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          result.name ??
                                                              'Unknown',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        if (result
                                                                .releaseDate !=
                                                            null) ...[
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            result.releaseDate!,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurfaceVariant,
                                                                ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(
                                                      Icons.chevron_right),
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
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                    child: Center(
                      child: isLoading
                          ? CircularProgressIndicator()
                          : Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Iconsax.play,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // Episode badge
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.video_circle,
                        size: 16,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'EP ${continueWatchingEntry.episodeNumber}',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: colorScheme.onTertiaryContainer),
                      ),
                    ],
                  ),
                ),
              ),

              // Time remaining badge
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.timer_1,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatRemainingTime(
                          continueWatchingEntry.progressInSeconds ?? 0,
                          continueWatchingEntry.durationInSeconds ?? 0,
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: colorScheme.onPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  continueWatchingEntry.animeTitle ?? 'Unknown Anime',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  continueWatchingEntry.episodeTitle ??
                      'Episode ${continueWatchingEntry.episodeNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
