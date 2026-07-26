import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:skeletonizer/skeletonizer.dart';

final sourceDiscoverFeedProvider = FutureProvider.autoDispose
    .family<List<UnifiedMedia>, ({SourceInfo info, MediaType type})>((
      ref,
      arg,
    ) async {
      ref.keepAlive();
      if (arg.type == MediaType.ANIME) {
        final source = ref.read(animeSourceProvider(arg.info));
        try {
          final trending = await source.getTrending();
          if (trending.isNotEmpty) return trending;
        } catch (_) {}
        return await source.search('', arg.type, page: 1);
      } else {
        final source = ref.read(mangaSourceProvider(arg.info));
        try {
          final trending = await source.getTrending();
          if (trending.isNotEmpty) return trending;
        } catch (_) {}
        return await source.search('', arg.type, page: 1);
      }
    });

class DynamicSourceFeed extends ConsumerWidget {
  final MediaType type;
  final ValueChanged<String>? onSourceSelect;

  const DynamicSourceFeed({super.key, required this.type, this.onSourceSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(discoveryPrefsProvider);
    final sourcesAsync = type == MediaType.ANIME
        ? ref.watch(availableAnimeSourcesProvider)
        : ref.watch(availableMangaSourcesProvider);

    return sourcesAsync.when(
      data: (allSources) {
        final active = allSources
            .where((s) => prefs.activeSources.contains(s.id))
            .toList();
        if (active.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.extension_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No active ${type.name.toLowerCase()} sources',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enable extension sources in Discovery settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 60, bottom: 120),
          itemCount: active.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SourceFeedRow(
                type: type,
                info: active[index],
                onSourceSelect: onSourceSelect,
              ),
            );
          },
        );
      },
      loading: () {
        final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
        final isWide = ref.watch(
          uiPrefsProvider.select((p) => p.isMediaCardWide(style.name)),
        );
        final height = style.getLayout(isWideMode: isWide).height;

        return Skeletonizer(
          enabled: true,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 80, bottom: 120),
            itemCount: 3,
            itemBuilder: (context, index) {
              return HorizontalSection<UnifiedMedia>(
                title: 'Loading Extension Source',
                height: height,
                data: const AsyncValue.loading(),
                itemBuilder: (_, __) => const SizedBox.shrink(),
                skeletonItemBuilder: (context, i) {
                  return MediaCard(
                    tag: 'skeleton-src-feed-$index-$i',
                    title: 'Placeholder Media Title Name',
                    imageUrl: '',
                    style: style,
                    format: 'TV',
                    score: 8.5,
                    year: '2026',
                    onTap: () {},
                  );
                },
              );
            },
          ),
        );
      },
      error: (e, _) => Center(child: Text('Failed to load sources: $e')),
    );
  }
}

class SourceFeedRow extends ConsumerWidget {
  final MediaType type;
  final SourceInfo info;
  final ValueChanged<String>? onSourceSelect;

  const SourceFeedRow({
    super.key,
    required this.type,
    required this.info,
    this.onSourceSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = (info: info, type: type);
    final catalogState = ref.watch(sourceDiscoverFeedProvider(arg));
    final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
    final isWide = ref.watch(
      uiPrefsProvider.select((p) => p.isMediaCardWide(style.name)),
    );

    return catalogState.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return HorizontalSection(
          title: info.name,
          height: style.getLayout(isWideMode: isWide).height,
          onMoreTap: () {
            if (onSourceSelect != null) {
              onSourceSelect!(info.id);
            } else {
              context.push('/discover?source=${info.id}&type=${type.id}');
            }
          },
          data: AsyncValue.data(items),
          itemBuilder: (context, item) {
            return MediaCard(
              tag: 'src-${info.id}-${item.id}',
              format: item.format,
              score: item.score,
              status: item.status,
              genres: item.genres,
              year: item.season,
              title: item.title.availableTitle,
              imageUrl: item.cover ?? '',
              style: style,
              onTap: () => context.push(
                '/details/${item.type.id}?tag=src-${info.id}-${item.id}',
                extra: item,
              ),
            );
          },
        );
      },
      loading: () => HorizontalSection<UnifiedMedia>(
        title: info.name,
        height: style.getLayout(isWideMode: isWide).height,
        data: const AsyncValue.loading(),
        itemBuilder: (_, __) => const SizedBox.shrink(),
        skeletonItemBuilder: (context, index) {
          return MediaCard(
            tag: 'skeleton-src-row-${info.id}-$index',
            title: 'Placeholder Media Title Name',
            imageUrl: '',
            style: style,
            format: 'TV',
            score: 8.5,
            year: '2026',
            onTap: () {},
          );
        },
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
