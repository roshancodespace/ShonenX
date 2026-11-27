import 'dart:typed_data';

class ChapterPage {
  final String url;
  final Map<String, String>? headers;
  final Uint8List? bytes;

  const ChapterPage({required this.url, this.headers, this.bytes});

  ChapterPage copyWith({
    String? url,
    Map<String, String>? headers,
    Uint8List? bytes,
  }) {
    return ChapterPage(
      url: url ?? this.url,
      headers: headers ?? this.headers,
      bytes: bytes ?? this.bytes,
    );
  }
}
