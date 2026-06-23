class ChapterPage {
  final String url;
  final Map<String, String>? headers;

  const ChapterPage({
    required this.url,
    this.headers,
  });

  ChapterPage copyWith({
    String? url,
    Map<String, String>? headers,
  }) {
    return ChapterPage(
      url: url ?? this.url,
      headers: headers ?? this.headers,
    );
  }
}
