class VideoStream {
  final String url;
  final Map<String, String>? headers;
  final String quality;
  final List<SubtitleTrack> subtitles;

  const VideoStream({
    required this.url,
    this.headers,
    this.quality = 'Auto',
    this.subtitles = const [],
  });

  VideoStream copyWith({
    String? url,
    Map<String, String>? headers,
    String? quality,
    List<SubtitleTrack>? subtitles,
  }) {
    return VideoStream(
      url: url ?? this.url,
      headers: headers ?? this.headers,
      quality: quality ?? this.quality,
      subtitles: subtitles ?? this.subtitles,
    );
  }
}

class SubtitleTrack {
  final String url;
  final String language;

  const SubtitleTrack({required this.url, required this.language});

  static const none = SubtitleTrack(url: '', language: 'Off');
}
