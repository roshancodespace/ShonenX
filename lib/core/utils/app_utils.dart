import 'package:shonenx/core/models/anilist/media.dart';

List<Media> safeParse(String label, List list) {
  try {
    Map<String, dynamic> convertToStringKeys(Map<dynamic, dynamic> input) {
      return input.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), convertToStringKeys(value));
        } else if (value is List) {
          return MapEntry(key.toString(),
              value.map((v) => v is Map ? convertToStringKeys(v) : v).toList());
        }
        return MapEntry(key.toString(), value);
      });
    }

    return list
        .whereType<Map>()
        .map((item) => Media.fromJson(convertToStringKeys(item)))
        .toList();
  } catch (e, st) {
    print("⚠️ Failed to parse $label: $e\n$st");
    return [];
  }
}

int generateId() {
  final id = DateTime.now().millisecondsSinceEpoch;
  return id;
}
