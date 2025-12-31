// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class JikanMedia {
  final int malId;
  final String title;

  JikanMedia({
    required this.malId,
    required this.title,
  });

  JikanMedia copyWith({
    int? malId,
    String? title,
  }) {
    return JikanMedia(
      malId: malId ?? this.malId,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'malId': malId,
      'title': title,
    };
  }

  factory JikanMedia.fromMap(Map<String, dynamic> map) {
    return JikanMedia(
      malId: map['malId'] as int,
      title: map['title'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory JikanMedia.fromJson(String source) =>
      JikanMedia.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'JikanMedia(malId: $malId, title: $title)';

  @override
  bool operator ==(covariant JikanMedia other) {
    if (identical(this, other)) return true;

    return other.malId == malId && other.title == title;
  }

  @override
  int get hashCode => malId.hashCode ^ title.hashCode;
}
