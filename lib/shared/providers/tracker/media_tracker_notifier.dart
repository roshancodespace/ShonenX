import 'package:collection/collection.dart';
import 'package:shonenx/core/models/tracker/tracker_binding.dart';
import 'package:shonenx/core/models/tracker/tracker_type.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/repositories/interfaces/local_media_repository_interface.dart';
import 'package:shonenx/core/repositories/local_media_repository.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';
import 'package:shonenx/shared/providers/anilist_service_provider.dart';
import 'package:shonenx/shared/providers/mal_service_provider.dart';
import 'package:shonenx/shared/providers/tracker/tracker_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_tracker_notifier.g.dart';

class TrackerState {
  final bool isLoading;
  final List<TrackerBinding> bindings;
  final Map<TrackerType, UniversalMediaListEntry> entries;
  final Map<TrackerType, List<String>> supportedStatuses;
  final bool remoteLoaded;

  static const Map<TrackerType, List<String>> _defaultStatuses = {
    TrackerType.anilist: [
      'CURRENT',
      'COMPLETED',
      'PAUSED',
      'DROPPED',
      'PLANNING',
      'REPEATING',
    ],
    TrackerType.mal: ['CURRENT', 'COMPLETED', 'PAUSED', 'DROPPED', 'PLANNING'],
  };

  const TrackerState({
    this.isLoading = false,
    this.bindings = const [],
    this.entries = const {},
    this.supportedStatuses = _defaultStatuses,
    this.remoteLoaded = false,
  });

  TrackerState copyWith({
    bool? isLoading,
    List<TrackerBinding>? bindings,
    Map<TrackerType, UniversalMediaListEntry>? entries,
    Map<TrackerType, List<String>>? supportedStatuses,
    bool? remoteLoaded,
  }) {
    return TrackerState(
      isLoading: isLoading ?? this.isLoading,
      bindings: bindings ?? this.bindings,
      entries: entries ?? this.entries,
      supportedStatuses: supportedStatuses ?? this.supportedStatuses,
      remoteLoaded: remoteLoaded ?? this.remoteLoaded,
    );
  }
}

@Riverpod(keepAlive: true)
class MediaTracker extends _$MediaTracker {
  @override
  TrackerState build(String mediaId) {
    _loadLocalBindings();
    return const TrackerState();
  }

  Future<void> _loadLocalBindings() async {
    final bindings = await _repo.getBindings(mediaId);
    state = state.copyWith(bindings: bindings);
    await fetchRemoteEntries();
  }

  Future<void> fetchRemoteEntries() async {
    if (state.remoteLoaded) return;

    final currentState = state;
    if (currentState.bindings.isEmpty) {
      state = currentState.copyWith(remoteLoaded: true);
      return;
    }

    state = currentState.copyWith(isLoading: true);

    try {
      final entries = <TrackerType, UniversalMediaListEntry>{};

      await Future.wait(
        currentState.bindings.map((binding) async {
          final remoteIdStr = binding.remoteId;
          if (remoteIdStr == null) return;

          final id = int.tryParse(remoteIdStr);
          if (id == null) return;

          try {
            UniversalMediaListEntry? entry;
            if (binding.type == TrackerType.anilist) {
              entry = await ref.read(anilistServiceProvider).getAnimeEntry(id);
            } else if (binding.type == TrackerType.mal) {
              entry = await ref.read(malServiceProvider).getAnimeEntry(id);
            }
            if (entry != null) entries[binding.type] = entry;
          } catch (e) {
            AppLogger.e(
              'Failed to fetch ${binding.type.name} entry for ID ${binding.remoteId}',
              e,
            );
          }
        }),
      );

      state = state.copyWith(
        isLoading: false,
        entries: entries,
        remoteLoaded: true,
      );

      await _syncProgressFromActiveTracker(entries);
    } catch (e) {
      state = state.copyWith(isLoading: false, remoteLoaded: true);
    }
  }

  Future<void> addTrackerBinding(TrackerType type, String remoteId) async {
    final currentState = state;
    state = currentState.copyWith(isLoading: true);

    try {
      final newBinding = TrackerBinding(type: type, remoteId: remoteId);

      await _repo.addBinding(mediaId, type, remoteId);

      UniversalMediaListEntry? newEntry;
      final id = int.tryParse(remoteId);
      if (id != null) {
        try {
          if (type == TrackerType.anilist) {
            final anilist = ref.read(anilistServiceProvider);
            newEntry = await anilist.getAnimeEntry(id);
            newEntry ??= await anilist.updateUserAnimeList(
              mediaId: id,
              status: 'CURRENT',
            );
          } else if (type == TrackerType.mal) {
            final mal = ref.read(malServiceProvider);
            newEntry = await mal.getAnimeEntry(id);
            newEntry ??= await mal.updateUserAnimeList(
              mediaId: id,
              status: 'CURRENT',
            );
          }
        } catch (e) {
          AppLogger.e(
            'Failed to fetch or create new ${type.name} entry for ID $remoteId',
            e,
          );
        }
      }

      final updatedBindings = List<TrackerBinding>.from(currentState.bindings)
        ..removeWhere((b) => b.type == type)
        ..add(newBinding);

      final updatedEntries = Map<TrackerType, UniversalMediaListEntry>.from(
        currentState.entries,
      );
      if (newEntry != null) {
        updatedEntries[type] = newEntry;
      }

      state = currentState.copyWith(
        isLoading: false,
        bindings: updatedBindings,
        entries: updatedEntries,
      );

      await _syncProgressFromActiveTracker(updatedEntries);
    } catch (e) {
      state = currentState.copyWith(isLoading: false);
      throw Exception('Failed to bind tracker: $e');
    }
  }

  ///Sync specific trackers directly
  Future<void> syncTrackers({
    required List<TrackerBinding> bindings,
    String? status,
    int? progress,
    double? score,
    int? repeat,
    String? notes,
    bool? isPrivate,
  }) async {
    final Map<TrackerType, TrackerService> services = {
      TrackerType.anilist: ref.read(anilistServiceProvider),
      TrackerType.mal: ref.read(malServiceProvider),
    };

    final List<Future<void>> tasks = [];

    for (final binding in bindings) {
      if (binding.remoteId == null) continue;
      final service = services[binding.type];

      if (service == null) continue;

      tasks.add(
        service
            .updateEntry(
              remoteId: binding.remoteId!,
              status: status,
              progress: progress,
              score: score,
              repeat: repeat,
              notes: notes,
              isPrivate: isPrivate,
            )
            .then((value) {
              state.entries[binding.type] = state.entries[binding.type]!
                  .copyWith(
                    status: status,
                    progress: progress,
                    score: score,
                    repeat: repeat,
                    notes: notes,
                    isPrivate: isPrivate,
                  );
            })
            .catchError((e) {
              AppLogger.e(
                'Failed to update tracker entry for ${binding.type}',
                e,
              );
              return;
            }),
      );
    }
  }

  /// Extracted sync for the UI
  Future<void> syncForTracker(
    TrackerType type, {
    String? status,
    int? progress,
    double? score,
  }) async {
    final currentState = state;
    state = currentState.copyWith(isLoading: true);

    try {
      final binding = currentState.bindings.firstWhereOrNull(
        (b) => b.type == type,
      );

      if (binding == null || binding.remoteId == null) {
        state = currentState.copyWith(isLoading: false);
        return;
      }

      await syncTrackers(
        bindings: [binding],
        status: status,
        progress: progress,
        score: score,
      );

      final updatedEntries = Map<TrackerType, UniversalMediaListEntry>.from(
        currentState.entries,
      );

      if (updatedEntries.containsKey(type)) {
        updatedEntries[type] = updatedEntries[type]!.copyWith(
          status: status,
          progress: progress,
          score: score,
        );
      }

      state = currentState.copyWith(isLoading: false, entries: updatedEntries);
    } catch (e) {
      state = currentState.copyWith(isLoading: false);
      throw Exception('Failed to sync ${type.name}: $e');
    }
  }

  LocalMediaRepositoryInterface get _repo => ref.read(localMediaRepoProvider);

  Future<void> _syncProgressFromActiveTracker(
    Map<TrackerType, UniversalMediaListEntry> entries,
  ) async {
    try {
      final authState = ref.read(authProvider);
      final activeType = authState.activePlatform == AuthPlatform.anilist
          ? TrackerType.anilist
          : TrackerType.mal;

      final entry = entries[activeType];
      if (entry == null || entry.progress <= 0) return;

      final repo = ref.read(watchProgressRepositoryProvider);
      final local = repo.getProgress(mediaId);

      if (local != null && local.currentEpisode >= entry.progress) return;

      final media = entry.media;
      final updated =
          (local ??
                  AnimeWatchProgressEntry(
                    animeId: mediaId,
                    animeTitle:
                        media.title.english ??
                        media.title.romaji ??
                        media.title.native ??
                        '',
                    animeFormat: media.format,
                    animeCover:
                        media.coverImage.large ?? media.coverImage.medium ?? '',
                    totalEpisodes: media.episodes ?? 0,
                    episodesProgress: const {},
                    lastUpdated: DateTime.now(),
                    currentEpisode: entry.progress,
                    status: 'watching',
                  ))
              .copyWith(
                currentEpisode: entry.progress,
                lastUpdated: DateTime.now(),
              );

      await repo.saveProgress(updated);
      AppLogger.d(
        'Synced local progress from ${activeType.name}: ep ${entry.progress}',
      );
    } catch (e) {
      AppLogger.e('Failed to sync local progress from tracker', e);
    }
  }

  Future<bool> toggleFavorite(UniversalMedia media) =>
      _repo.toggleFavorite(media);

  Future<bool> isFavorite(String mediaId) => _repo.isFavorite(mediaId);

  Future<UniversalMediaListEntry?> getLocalEntry() => _repo.getEntry(mediaId);

  Future<void> saveLocalEntry(
    UniversalMedia media, {
    required String status,
    required double score,
    required int progress,
    required int repeat,
    required String notes,
    required bool isPrivate,
    DateTime? startedAt,
    DateTime? completedAt,
  }) => _repo.saveEntry(
    media,
    status: status,
    score: score,
    progress: progress,
    repeat: repeat,
    notes: notes,
    isPrivate: isPrivate,
    startedAt: startedAt,
    completedAt: completedAt,
  );

  Future<void> deleteLocalEntry() => _repo.deleteEntry(mediaId);
}
