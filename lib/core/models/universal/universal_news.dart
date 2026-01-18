import 'package:hive_ce/hive.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'universal_news.g.dart';

@HiveType(typeId: HiveTypeIds.news)
class UniversalNews {
  @HiveField(0)
  final String? title;
  @HiveField(1)
  final String? url;
  @HiveField(2)
  final String? imageUrl;
  @HiveField(3)
  final String? date;
  @HiveField(4)
  final String? excerpt;
  @HiveField(5)
  @HiveField(5)
  final String? body;
  @HiveField(6)
  final bool isRead;

  const UniversalNews({
    this.title,
    this.url,
    this.imageUrl,
    this.date,
    this.excerpt,
    this.body,
    this.isRead = false,
  });

  factory UniversalNews.fromJson(Map<String, dynamic> json) {
    return UniversalNews(
      title: json['title'],
      url: json['url'],
      imageUrl: json['imageUrl'],
      date: json['date'],
      excerpt: json['excerpt'],
      body: json['body'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'imageUrl': imageUrl,
      'date': date,
      'excerpt': excerpt,
      'body': body,
    };
  }

  UniversalNews copyWith({
    String? title,
    String? url,
    String? imageUrl,
    String? date,
    String? excerpt,
    String? body,
    bool? isRead,
  }) {
    return UniversalNews(
      title: title ?? this.title,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      excerpt: excerpt ?? this.excerpt,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
    );
  }
}
