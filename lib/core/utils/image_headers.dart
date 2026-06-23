import 'dart:convert';

String encodeUrlHeaders(String url, Map<String, String> headers) {
  final jsonStr = jsonEncode(headers);
  final encoded = base64Url.encode(utf8.encode(jsonStr));
  return '$url#$encoded';
}

Map<String, String> decodeUrlHeaders(String? url) {
  if (url == null || !url.contains('#')) return const {};
  final fragment = url.split('#').last;
  try {
    final decodedJson = utf8.decode(base64Url.decode(fragment));
    final decodedMap = jsonDecode(decodedJson) as Map<String, dynamic>;
    return decodedMap.map((key, value) => MapEntry(key, value.toString()));
  } catch (_) {
    return {'Referer': fragment};
  }
}
