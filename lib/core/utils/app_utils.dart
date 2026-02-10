import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/utils/app_logger.dart';

List<UniversalMedia> safeParse(String label, List list) {
  try {
    Map<String, dynamic> convertToStringKeys(Map<dynamic, dynamic> input) {
      return input.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), convertToStringKeys(value));
        } else if (value is List) {
          return MapEntry(
            key.toString(),
            value.map((v) => v is Map ? convertToStringKeys(v) : v).toList(),
          );
        }
        return MapEntry(key.toString(), value);
      });
    }

    return list
        .whereType<Map>()
        .map((item) => UniversalMedia.fromJson(convertToStringKeys(item)))
        .toList();
  } catch (e, st) {
    AppLogger.e("⚠️ Failed to parse $label: $e\n$st");
    return [];
  }
}

int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
