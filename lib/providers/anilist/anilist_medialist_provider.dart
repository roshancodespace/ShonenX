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
      log('$status list fetched successfully');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errors: {...state.errors, status: e.toString()},
        fetchedStatuses: {
          ...state.fetchedStatuses,
          status
        }, // Mark as fetched even on error
      );
      log('❌ Error fetching $status: $e');
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
      log('Favorites fetched successfully');
    } catch (e) {
      log('Error fetching favorites: $e');
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
