enum SourceType { inbuilt, extension }

class SourceInfo {
  final String id;
  final String name;
  final SourceType type;
  final String? iconUrl;

  const SourceInfo({
    required this.id,
    required this.name,
    required this.type,
    this.iconUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceInfo &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, type);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'iconUrl': iconUrl,
      };

  factory SourceInfo.fromMap(Map<String, dynamic> map) {
    return SourceInfo(
      id: map['id'],
      name: map['name'],
      type: SourceType.values.firstWhere((e) => e.name == map['type']),
      iconUrl: map['iconUrl'],
    );
  }
}