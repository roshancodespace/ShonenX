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
}

class SubtitleTrack {
  final String url;
  final String language;

  const SubtitleTrack({required this.url, required this.language});

  static const none = SubtitleTrack(url: '', language: 'Off');
}
