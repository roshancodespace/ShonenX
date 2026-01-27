class HomeSection {
  final String id;
  final String title;
  final HomeSectionType type;
  final bool enabled;
  final String? dataId;

  const HomeSection({
    required this.id,
    required this.title,
    required this.type,
    this.enabled = true,
    this.dataId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'enabled': enabled,
      'dataId': dataId,
    };
  }

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      id: json['id'],
      title: json['title'],
      type: HomeSectionType.values.byName(json['type']),
      enabled: json['enabled'] ?? true,
      dataId: json['dataId'],
    );
  }

  HomeSection copyWith({String? title, bool? enabled}) {
    return HomeSection(
      id: id,
      title: title ?? this.title,
      type: type,
      enabled: enabled ?? this.enabled,
      dataId: dataId,
    );
  }
}

enum HomeSectionType { spotlight, continueWatching, standard, watchlist }
