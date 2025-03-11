import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/anilist/services/anilist_service.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/providers/anilist/anilist_user_provider.dart';

class AnimeListState {
  final Map<String, List<MediaListGroup>> mediaListGroups;
  final bool isLoading;
  final Map<String, String?> errors;
  final List<Media> favorites;
  final Set<String> fetchedStatuses; // Track which statuses have been fetched

  AnimeListState({
    this.mediaListGroups = const {},
    this.isLoading = false,
    this.errors = const {},
    this.favorites = const [],
    this.fetchedStatuses = const {},
  });

  AnimeListState copyWith({
    Map<String, List<MediaListGroup>>? mediaListGroups,
    bool? isLoading,
    Map<String, String?>? errors,
    List<Media>? favorites,
    Set<String>? fetchedStatuses,
  }) {
    return AnimeListState(
      mediaListGroups: mediaListGroups ?? this.mediaListGroups,
      isLoading: isLoading ?? this.isLoading,
      errors: errors ?? this.errors,
      favorites: favorites ?? this.favorites,
      fetchedStatuses: fetchedStatuses ?? this.fetchedStatuses,
    );
  }
}

class AnimeListNotifier extends StateNotifier<AnimeListState> {
  final AnilistService _anilistService;
  final String accessToken;
  final String userId;

  AnimeListNotifier({
    required AnilistService anilistService,
    required this.accessToken,
    required this.userId,
  })  : _anilistService = anilistService,
        super(AnimeListState()) {
    if (accessToken.isEmpty || userId.isEmpty) {
      log('Access token or user ID is empty',
          error: true, name: "animeListProvider");
    }
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    await Future.wait([
      fetchAllAnimeLists(),
      fetchFavorites(),
    ]);
  }

  Future<void> fetchAnimeListByStatus(String status) async {
    state = state.copyWith(
      isLoading: true,
      errors: {...state.errors, status: null},
    );

    try {
      if (accessToken.isEmpty || userId.isEmpty) {
        log('Access token or user ID is empty',
            error: true, name: "animeListProvider");
      }
      final data = await _anilistService.getUserAnimeList(
        accessToken: accessToken,
        userId: userId,
        type: 'ANIME',
        status: status,
      );

      state = state.copyWith(
        mediaListGroups: {
          ...state.mediaListGroups,
          status: data.lists,
        },
        isLoading: false,
        fetchedStatuses: {...state.fetchedStatuses, status},
      );
      log('$status ✅', name: "animeListProvider");
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errors: {...state.errors, status: e.toString()},
        fetchedStatuses: {
          ...state.fetchedStatuses,
          status
        }, // Mark as fetched even on error
      );
      log('❌ Error fetching $status: $e',
          error: true, name: "animeListProvider");
    }
  }

  Future<void> fetchAllAnimeLists() async {
    if (state.isLoading) return; // Prevent concurrent fetches

    state = state.copyWith(isLoading: true, errors: {});

    final statuses = ['CURRENT', 'COMPLETED', 'PAUSED', 'DROPPED', 'PLANNING'];
    await Future.wait(
      statuses.map((status) => fetchAnimeListByStatus(status)),
    );
  }

  Future<void> fetchFavorites() async {
    try {
      final favorites = await _anilistService.getFavorites(
        userId: int.parse(userId),
        accessToken: accessToken,
      );
      state = state.copyWith(
        favorites: favorites?.anime ?? [],
      );
      log('Favorites fetched successfully', name: "animeListProvider");
    } catch (e) {
      log('Error fetching favorites: $e', name: "animeListProvider");
    }
  }

  // Method to refresh a specific status
  Future<void> refreshStatus(String status) async {
    state = state.copyWith(
      fetchedStatuses: state.fetchedStatuses.difference({status}),
    );
    await fetchAnimeListByStatus(status);
  }

  // Method to refresh all data
  Future<void> refreshAll() async {
    state = state.copyWith(fetchedStatuses: {});
    await fetchInitialData();
  }

  // Method to add or remove a favorite
  Future<void> toggleFavoritesStatic(List<Media> favorites) async {
    final currentFavorites =
        state.favorites.toSet(); // Convert to Set for efficient lookup

    // Update favorites by adding new ones and removing existing ones
    for (var media in favorites) {
      if (currentFavorites.contains(media)) {
        currentFavorites.remove(media); // Remove existing favorite
      } else {
        currentFavorites.add(media); // Add new favorite
      }
    }

    state = state.copyWith(
        favorites:
            currentFavorites.toList()); // Update favorites with the new list
  }

  /// Toggle the status of a Media item locally without fetching from the server
  void toggleStatusStatic({
    required Media media,
    required String? newStatus, // Null means removal
    int? entryId, // Optional, needed for removal or initial entry
    int? progress, // Optional, to preserve or update progress
    int? score, // Optional, to preserve or update score
  }) {
    final currentGroups =
        Map<String, List<MediaListGroup>>.from(state.mediaListGroups);
    MediaList? existingEntry;

    // Step 1: Find and remove the media from its current status (if it exists)
    for (var status in currentGroups.keys) {
      final groupList = List<MediaListGroup>.from(currentGroups[status] ?? []);
      for (var group in groupList) {
        final entries = List<MediaList>.from(group.entries);
        existingEntry = entries.firstWhere(
          (entry) => entry.media.id == media.id,
          orElse: () => MediaList(
              media: media,
              status: '',
              score: 0,
              progress: 0), // Dummy for not found
        );
        if (existingEntry.media.id != null) {
          entries.remove(existingEntry);
          if (entries.isEmpty) {
            groupList.remove(group); // Remove empty group
          }
          currentGroups[status] = groupList;
          break; // Found and removed, exit loop
        }
      }
    }

    // Step 2: Add the media to the new status (if newStatus is provided)
    if (newStatus != null) {
      final newGroupList =
          List<MediaListGroup>.from(currentGroups[newStatus] ?? []);
      final existingGroup = newGroupList.firstWhere(
        (group) => group.name == newStatus, // Match by name (status)
        orElse: () => MediaListGroup(name: newStatus, entries: []),
      );

      // Create or update the MediaList entry
      final updatedEntry = MediaList(
        media: media,
        status: newStatus,
        score: score ?? existingEntry?.score ?? 0,
        progress: progress ?? existingEntry?.progress ?? 0,
      );

      final updatedEntries = List<MediaList>.from(existingGroup.entries)
        ..add(updatedEntry);
      final updatedGroup =
          MediaListGroup(name: newStatus, entries: updatedEntries);

      // Replace or add the group
      if (newGroupList.contains(existingGroup)) {
        newGroupList[newGroupList.indexOf(existingGroup)] = updatedGroup;
      } else {
        newGroupList.add(updatedGroup);
      }
      currentGroups[newStatus] = newGroupList;
    }

    // Step 3: Update the state
    state = state.copyWith(mediaListGroups: currentGroups);
    log('Toggled status for ${media.title?.english ?? media.id} to $newStatus',
        name: "animeListProvider");
  }

  // Convenience method for single status toggle
  void toggleStatusStaticSingle(
    Media media,
    String? newStatus, {
    int? entryId,
    int? progress,
    int? score,
  }) {
    toggleStatusStatic(
      media: media,
      newStatus: newStatus,
      entryId: entryId,
      progress: progress,
      score: score,
    );
  }
}

final animeListProvider =
    StateNotifierProvider<AnimeListNotifier, AnimeListState>((ref) {
  final userState = ref.watch(userProvider);

  if (userState == null ||
      userState.accessToken.isEmpty ||
      userState.id == null) {
    return AnimeListNotifier(
      anilistService: AnilistService(),
      accessToken: '',
      userId: '',
    );
  }

  return AnimeListNotifier(
    anilistService: AnilistService(),
    accessToken: userState.accessToken,
    userId: userState.id.toString(),
  );
});
