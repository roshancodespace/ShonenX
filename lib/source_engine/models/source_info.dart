import 'package:shonenx/shared/models/unified_media.dart';

enum SourceType { inbuilt, extension }

class SourceInfo {
  final String id;
  final String name;
  final SourceType type;
  final MediaType mediaType;
  final String? iconUrl;
  final String? baseUrl;
  final String? lang;
  final bool isNsfw;

  const SourceInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.mediaType,
    this.iconUrl,
    this.baseUrl,
    this.lang,
    this.isNsfw = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceInfo &&
          id == other.id &&
          type == other.type &&
          mediaType == other.mediaType;

  @override
  int get hashCode => Object.hash(id, type, mediaType);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'mediaType': mediaType.name,
        'iconUrl': iconUrl,
        'lang': lang,
        'isNsfw': isNsfw,
      };

  factory SourceInfo.fromMap(Map<String, dynamic> map) {
    return SourceInfo(
      id: map['id'],
      name: map['name'],
      type: SourceType.values.firstWhere((e) => e.name == map['type']),
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == map['mediaType'],
        orElse: () => MediaType.ANIME,
      ),
      iconUrl: map['iconUrl'],
      lang: map['lang'],
      isNsfw: map['isNsfw'] ?? false,
    );
  }
}