class CommentumMedia {
  final String mediaId;
  final String mediaType;
  final String mediaTitle;
  final int mediaYear;
  final String mediaPoster;

  CommentumMedia({
    required this.mediaId,
    required this.mediaType,
    required this.mediaTitle,
    required this.mediaYear,
    required this.mediaPoster,
  });

  factory CommentumMedia.fromJson(Map<String, dynamic> json) {
    return CommentumMedia(
      mediaId: json['mediaId'],
      mediaType: json['mediaType'],
      mediaTitle: json['mediaTitle'],
      mediaYear: json['mediaYear'],
      mediaPoster: json['mediaPoster'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaId': mediaId,
      'mediaType': mediaType,
      'mediaTitle': mediaTitle,
      'mediaYear': mediaYear,
      'mediaPoster': mediaPoster,
    };
  }
}
