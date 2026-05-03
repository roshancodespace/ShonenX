import 'DMedia.dart';

class Pages {
  List<DMedia> list;
  bool hasNextPage;

  Pages({required this.list, this.hasNextPage = false});

  factory Pages.fromJson(Map<String, dynamic> json) {
    return Pages(
      list: json['list'] != null
          ? (json['list'] as List)
                .map((e) => DMedia.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : [],
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'list': list.map((v) => v.toJson()).toList(),
    'hasNextPage': hasNextPage,
  };
}
