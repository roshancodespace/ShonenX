// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class JikanMedia {
  final int mal_id;
  final String title;

  JikanMedia({
    required this.mal_id,
    required this.title,
  });

  JikanMedia copyWith({
    int? mal_id,
    String? title,
  }) {
    return JikanMedia(
      mal_id: mal_id ?? this.mal_id,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mal_id': mal_id,
      'title': title,
    };
  }

  factory JikanMedia.fromMap(Map<String, dynamic> map) {
    return JikanMedia(
      mal_id: map['mal_id'] as int,
      title: map['title'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory JikanMedia.fromJson(String source) =>
      JikanMedia.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'JikanMedia(mal_id: $mal_id, title: $title)';

  @override
  bool operator ==(covariant JikanMedia other) {
    if (identical(this, other)) return true;

    return other.mal_id == mal_id && other.title == title;
  }

  @override
  int get hashCode => mal_id.hashCode ^ title.hashCode;
}
