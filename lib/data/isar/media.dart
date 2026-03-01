import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:isar_community/isar.dart';
part 'media.g.dart';

@collection
@Name("Media")
class Media {
  Id? id;

  String? name;

  String? link;

  String? imageUrl;

  String? description;

  @enumerated
  late Status status;

  @enumerated
  late ItemType itemType;

  List<String>? genre;

  bool? favorite;

  String? source;

  String? lang;

  int? dateAdded;

  int? lastUpdate;

  int? progress;

  List<int>? categories;

  List<byte>? customCoverImage;

  String? customCoverFromTracker;

  int? updatedAt;

  Media({
    this.id = Isar.autoIncrement,
    required this.source,
    this.favorite = false,
    required this.genre,
    required this.imageUrl,
    required this.lang,
    required this.link,
    required this.name,
    required this.status,
    required this.description,
    this.itemType = ItemType.manga,
    this.dateAdded,
    this.lastUpdate,
    this.progress,
    this.categories,
    this.customCoverImage,
    this.customCoverFromTracker,
    this.updatedAt = 0,
  });

  Media.fromJson(Map<String, dynamic> json) {
    categories = json['categories']?.cast<int>();
    customCoverImage = json['customCoverImage']?.cast<int>();
    dateAdded = json['dateAdded'];
    description = json['description'];
    favorite = json['favorite']!;
    genre = json['genre']?.cast<String>();
    id = json['id'];
    imageUrl = json['imageUrl'];
    itemType = ItemType.values[json['itemType'] ?? 0];
    lang = json['lang'];
    lastUpdate = json['lastUpdate'];
    link = json['link'];
    name = json['name'];
    source = json['source'];
    status = Status.values[json['status']];
    progress = json['progress'];
    customCoverFromTracker = json['customCoverFromTracker'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() => {
    'categories': categories,
    'customCoverImage': customCoverImage,
    'dateAdded': dateAdded,
    'description': description,
    'favorite': favorite,
    'genre': genre,
    'id': id,
    'imageUrl': imageUrl,
    'itemType': itemType.index,
    'lang': lang,
    'lastUpdate': lastUpdate,
    'link': link,
    'name': name,
    'progress': progress,
    'source': source,
    'status': status.index,
    'customCoverFromTracker': customCoverFromTracker,
    'updatedAt': updatedAt ?? 0,
  };
}

enum Status {
  ongoing,
  completed,
  canceled,
  unknown,
  onHiatus,
  publishingFinished,
}
