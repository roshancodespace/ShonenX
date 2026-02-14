enum CommentStatus { active, hidden, removed, deleted }

class Comment {
  final String id;
  final String content;
  final int score;
  final CommentStatus status;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Comment> replies;
  final bool hasMoreReplies;
  final int repliesCount;
  final int? userVote;

  Comment({
    required this.id,
    required this.content,
    required this.score,
    required this.status,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.replies,
    required this.hasMoreReplies,
    required this.repliesCount,
    this.userVote,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return Comment(
      id: json['id']?.toString() ?? '',
      content: json['content'] ?? '',
      score: json['score'] ?? 0,
      status: CommentStatus.values
              .where((e) => e.name == json['status'])
              .firstOrNull ??
          CommentStatus.active,
      username: user?['username'] ?? 'Unknown',
      avatarUrl: user?['avatar_url'],
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e))
              .toList() ??
          [],
      hasMoreReplies: json['has_more_replies'] ?? false,
      repliesCount: json['replies_count'] ?? 0,
      userVote: json['user_vote'],
    );
  }

  Comment copyWith({
    String? id,
    String? content,
    int? score,
    CommentStatus? status,
    String? username,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Comment>? replies,
    bool? hasMoreReplies,
    int? repliesCount,
    int? userVote,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      score: score ?? this.score,
      status: status ?? this.status,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replies: replies ?? this.replies,
      hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
      repliesCount: repliesCount ?? this.repliesCount,
      userVote: userVote ?? this.userVote,
    );
  }
}
