class Comment {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String clientType;
  final String userId;
  final String mediaId;
  final String content;
  final String username;
  final String userAvatar;
  final String userRole;

  final String mediaType;
  final String mediaTitle;
  final int mediaYear;
  final String mediaPoster;

  final int? parentId;

  final bool deleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  final bool pinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;

  final bool locked;
  final DateTime? lockedAt;
  final String? lockedBy;

  final bool edited;
  final DateTime? editedAt;
  final int editCount;

  final int upvotes;
  final int downvotes;
  final int voteScore;

  final Map<String, String> userVotes;

  final bool reported;
  final int reportCount;

  final List<String> tags;

  final bool userBanned;
  final DateTime? userMutedUntil;
  final bool userShadowBanned;
  final int userWarnings;

  final List<Comment> replies;

  Comment({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.clientType,
    required this.userId,
    required this.mediaId,
    required this.content,
    required this.username,
    required this.userAvatar,
    required this.userRole,
    required this.mediaType,
    required this.mediaTitle,
    required this.mediaYear,
    required this.mediaPoster,
    required this.parentId,
    required this.deleted,
    required this.deletedAt,
    required this.deletedBy,
    required this.pinned,
    required this.pinnedAt,
    required this.pinnedBy,
    required this.locked,
    required this.lockedAt,
    required this.lockedBy,
    required this.edited,
    required this.editedAt,
    required this.editCount,
    required this.upvotes,
    required this.downvotes,
    required this.voteScore,
    required this.userVotes,
    required this.reported,
    required this.reportCount,
    required this.tags,
    required this.userBanned,
    required this.userMutedUntil,
    required this.userShadowBanned,
    required this.userWarnings,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      clientType: json['client_type'],
      userId: json['user_id'],
      mediaId: json['media_id'],
      content: json['content'],
      username: json['username'],
      userAvatar: json['user_avatar'],
      userRole: json['user_role'],
      mediaType: json['media_type'],
      mediaTitle: json['media_title'],
      mediaYear: json['media_year'],
      mediaPoster: json['media_poster'],
      parentId: json['parent_id'],
      deleted: json['deleted'],
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      deletedBy: json['deleted_by'],
      pinned: json['pinned'],
      pinnedAt:
          json['pinned_at'] != null ? DateTime.parse(json['pinned_at']) : null,
      pinnedBy: json['pinned_by'],
      locked: json['locked'],
      lockedAt:
          json['locked_at'] != null ? DateTime.parse(json['locked_at']) : null,
      lockedBy: json['locked_by'],
      edited: json['edited'],
      editedAt:
          json['edited_at'] != null ? DateTime.parse(json['edited_at']) : null,
      editCount: json['edit_count'],
      upvotes: json['upvotes'],
      downvotes: json['downvotes'],
      voteScore: json['vote_score'],
      userVotes: Map<String, String>.from(json['user_votes'] ?? {}),
      reported: json['reported'],
      reportCount: json['report_count'],
      tags: List<String>.from(json['tags'] ?? []),
      userBanned: json['user_banned'],
      userMutedUntil: json['user_muted_until'] != null
          ? DateTime.parse(json['user_muted_until'])
          : null,
      userShadowBanned: json['user_shadow_banned'],
      userWarnings: json['user_warnings'],
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((e) => Comment.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'client_type': clientType,
      'user_id': userId,
      'media_id': mediaId,
      'content': content,
      'username': username,
      'user_avatar': userAvatar,
      'user_role': userRole,
      'media_type': mediaType,
      'media_title': mediaTitle,
      'media_year': mediaYear,
      'media_poster': mediaPoster,
      'parent_id': parentId,
      'deleted': deleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted_by': deletedBy,
      'pinned': pinned,
      'pinned_at': pinnedAt?.toIso8601String(),
      'pinned_by': pinnedBy,
      'locked': locked,
      'locked_at': lockedAt?.toIso8601String(),
      'locked_by': lockedBy,
      'edited': edited,
      'edited_at': editedAt?.toIso8601String(),
      'edit_count': editCount,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'vote_score': voteScore,
      'user_votes': userVotes,
      'reported': reported,
      'report_count': reportCount,
      'tags': tags,
      'user_banned': userBanned,
      'user_muted_until': userMutedUntil?.toIso8601String(),
      'user_shadow_banned': userShadowBanned,
      'user_warnings': userWarnings,
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }
}
