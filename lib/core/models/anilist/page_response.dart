// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:shonenx/core/models/anilist/media_list_entry.dart';

class PageResponse {
  final PageInfo pageInfo;
  final List<MediaListEntry> mediaList;

  PageResponse({
    required this.pageInfo,
    required this.mediaList,
  });

  /// AniList JSON
  factory PageResponse.fromJson(Map<String, dynamic> json) {
    final page = json['Page'];
    return PageResponse(
      pageInfo: PageInfo.fromJson(page['pageInfo']),
      mediaList: (page['mediaList'] as List<dynamic>)
          .map((e) => MediaListEntry.fromJson(e))
          .toList(),
    );
  }

  /// MAL JSON
  factory PageResponse.fromMal(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final paging = json['paging'] ?? {};

    return PageResponse(
      pageInfo: PageInfo(
        total: json['total'] ?? data.length,
        currentPage: paging['current'] ?? 1,
        lastPage: paging['last'] ?? 1,
        hasNextPage: paging['next'] != null,
        perPage: json['limit'] ?? data.length,
      ),
      mediaList: data
          .map((e) => MediaListEntry.fromMal(e)) // <- you'll need to add a `fromMal` factory in MediaListEntry
          .toList(),
    );
  }
}

class PageInfo {
  final int total;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;
  final int perPage;

  PageInfo({
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.hasNextPage,
    required this.perPage,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) => PageInfo(
        total: json['total'] ?? 0,
        currentPage: json['currentPage'] ?? 1,
        lastPage: json['lastPage'] ?? 1,
        hasNextPage: json['hasNextPage'] ?? false,
        perPage: json['perPage'] ?? 25,
      );

  PageInfo copyWith({
    int? total,
    int? currentPage,
    int? lastPage,
    bool? hasNextPage,
    int? perPage,
  }) {
    return PageInfo(
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      perPage: perPage ?? this.perPage,
    );
  }
}
