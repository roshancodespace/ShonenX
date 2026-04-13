import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/core/services/mappers/list_entry_mapper.dart';

class PageResponseMapper {
  static PageResponse fromJson(Map<String, dynamic> json) {
    final page = json['Page'];
    if (page == null || page.isEmpty) {
      final pageInfo = json['pageInfo'];
      final items = json['items'] ?? json['nodes'];
      return PageResponse(
        pageInfo: PageInfoMapper.fromJson(pageInfo),
        mediaList: (items as List<dynamic>)
            .map((e) => MediaListEntryMapper.fromJson(e))
            .toList(),
      );
    }
    return PageResponse(
      pageInfo: PageInfoMapper.fromJson(page['pageInfo']),
      mediaList: (page['mediaList'] as List<dynamic>)
          .map((e) => MediaListEntryMapper.fromJson(e))
          .toList(),
    );
  }

  static PageResponse fromMal(Map<String, dynamic> json) {
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
      mediaList: data.map((e) => MediaListEntryMapper.fromMal(e)).toList(),
    );
  }
}

class PageInfoMapper {
  static PageInfo fromJson(Map<String, dynamic> json) => PageInfo(
        total: json['total'] ?? 0,
        currentPage: json['currentPage'] ?? 1,
        lastPage: json['lastPage'] ?? 1,
        hasNextPage: json['hasNextPage'] ?? false,
        perPage: json['perPage'] ?? 25,
      );
}
