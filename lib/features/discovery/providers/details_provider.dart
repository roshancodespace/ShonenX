import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class DetailsArgs {
  final String id;
  final MediaType type;
  final String? sourceId;

  const DetailsArgs(this.id, this.type, {this.sourceId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetailsArgs &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          sourceId == other.sourceId;

  @override
  int get hashCode => Object.hash(id, type, sourceId);
}

final detailsProvider = FutureProvider.autoDispose
    .family<UnifiedMedia, DetailsArgs>(
      retry: (retryCount, error) => null,
      (ref, args) async {
        if (args.sourceId != null) {
          final allSources = await ref.watch(
            args.type == MediaType.ANIME
                ? availableAnimeSourcesProvider.future
                : availableMangaSourcesProvider.future,
          );
          final sourceInfo = allSources.firstWhere(
            (s) => s.id == args.sourceId,
            orElse: () => throw StateError(
              'Source "${args.sourceId}" not found',
            ),
          );
          final source = args.type == MediaType.ANIME
              ? ref.read(animeSourceProvider(sourceInfo))
              : ref.read(mangaSourceProvider(sourceInfo));
          return source.getDetails(args.id, args.type);
        }

        // Tracker Mode: use the metadata tracker.
        final engine = ref.watch(metadataSourceProvider);
        return engine.getDetails(args.id, args.type);
      },
      name: 'detailsProvider',
    );
