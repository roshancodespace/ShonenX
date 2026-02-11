class CommentumStats {
  final int commentCount;
  final int totalUpvotes;
  final int totalDownvotes;
  final int netScore;

  CommentumStats({
    required this.commentCount,
    required this.totalUpvotes,
    required this.totalDownvotes,
    required this.netScore,
  });

  factory CommentumStats.fromJson(Map<String, dynamic> json) {
    return CommentumStats(
      commentCount: json['commentCount'],
      totalUpvotes: json['totalUpvotes'],
      totalDownvotes: json['totalDownvotes'],
      netScore: json['netScore'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentCount': commentCount,
      'totalUpvotes': totalUpvotes,
      'totalDownvotes': totalDownvotes,
      'netScore': netScore,
    };
  }
}
