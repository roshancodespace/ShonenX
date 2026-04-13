// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:shonenx/core/models/anilist/media_list_entry.dart';

class PageResponse {
  final PageInfo pageInfo;
  final List<MediaListEntry> mediaList;

  PageResponse({
    this.pageInfo = const PageInfo.empty(),
    this.mediaList = const [],
  });



  Map<String, dynamic> toJson() => {
    'pageInfo': pageInfo.toJson(),
    'items': mediaList.map((e) => e.toJson()).toList(),
  };
}

class PageInfo {
  final int total;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;
  final int perPage;

  const PageInfo({
    this.total = 0,
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasNextPage = false,
    this.perPage = 25,
  });

  const PageInfo.empty()
    : total = 0,
      currentPage = 1,
      lastPage = 1,
      hasNextPage = false,
      perPage = 25;



  Map<String, dynamic> toJson() => {
    'total': total,
    'currentPage': currentPage,
    'lastPage': lastPage,
    'hasNextPage': hasNextPage,
    'perPage': perPage,
  };

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
