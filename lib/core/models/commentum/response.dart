import 'package:shonenx/core/models/commentum/comment.dart';
import 'package:shonenx/core/models/commentum/comment_stats.dart';
import 'package:shonenx/core/models/commentum/media.dart';

class CommentumResponse {
  CommentumMedia media;
  List<Comment> comments;
  CommentumStats stats;
  CommentumPagination pagination;

  CommentumResponse({
    required this.media,
    required this.comments,
    required this.stats,
    required this.pagination,
  });

  factory CommentumResponse.fromJson(Map<String, dynamic> json) {
    return CommentumResponse(
      media: CommentumMedia.fromJson(json['media']),
      comments: (json['comments'] as List<dynamic>)
          .map((e) => Comment.fromJson(e))
          .toList(),
      stats: CommentumStats.fromJson(json['stats']),
      pagination: CommentumPagination.fromJson(json['pagination']),
    );
  }
}

class CommentumPagination {
  int page;
  int limit;
  int total;
  int totalPages;

  CommentumPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory CommentumPagination.fromJson(Map<String, dynamic> json) {
    return CommentumPagination(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
    );
  }
}
