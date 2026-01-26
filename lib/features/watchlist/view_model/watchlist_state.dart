import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/models/universal/universal_page_response.dart';

class WatchListState {
  final Map<String, List<UniversalMediaListEntry>> lists;
  final Map<String, UniversalPageInfo> pageInfo;
  final List<UniversalMediaListEntry> favorites;
  final Set<String> loadingStatuses;
  final Map<String, String> errors;
  final bool isLocal;

  const WatchListState({
    this.lists = const {},
    this.pageInfo = const {},
    this.favorites = const [],
    this.loadingStatuses = const {},
    this.errors = const {},
    this.isLocal = false,
  });

  List<UniversalMediaListEntry> listFor(String status) =>
      lists[status] ?? const [];

  bool isFavorite(String id) => favorites.any((m) => m.media.id == id);

  WatchListState copyWith({
    Map<String, List<UniversalMediaListEntry>>? lists,
    Map<String, UniversalPageInfo>? pageInfo,
    List<UniversalMediaListEntry>? favorites,
    Set<String>? loadingStatuses,
    Map<String, String>? errors,
    bool? isLocal,
  }) {
    return WatchListState(
      lists: lists ?? this.lists,
      pageInfo: pageInfo ?? this.pageInfo,
      favorites: favorites ?? this.favorites,
      loadingStatuses: loadingStatuses ?? this.loadingStatuses,
      errors: errors ?? this.errors,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}
