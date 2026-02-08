import 'package:dartotsu_extension_bridge/Models/DEpisode.dart';

class DMedia {
  String? title;
  String? url;
  String? cover;
  String? description;
  String? author;
  String? artist;
  List<String>? genre;
  List<DEpisode>? episodes;

  DMedia({
    this.title,
    this.url,
    this.cover,
    this.description,
    this.author,
    this.artist,
    this.genre,
    this.episodes,
  });

  factory DMedia.fromJson(Map<String, dynamic> json) {
    return DMedia(
      title: json['title'],
      url: json['url'],
      cover: json['cover'],
      description: json['description'],
      artist: json['artist'],
      author: json['author'],
      genre: json['genre'] != null ? List<String>.from(json['genre']) : [],
      episodes: json['episodes'] != null
          ? (json['episodes'] as List)
              .map((e) => DEpisode.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }

  factory DMedia.withUrl(String url) {
    return DMedia(
      title: '',
      url: url,
      cover: '',
      description: '',
      artist: '',
      author: '',
      genre: [],
      episodes: [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'cover': cover,
        'description': description,
        'author': author,
        'artist': artist,
        'genre': genre,
        'episodes': episodes?.map((e) => e.toJson()).toList(),
      };
}
