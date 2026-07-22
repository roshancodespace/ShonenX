class VideoStream {
  final String url;
  final Map<String, String>? headers;
  final String quality;
  final List<SubtitleTrack> subtitles;
  final String? size;

  const VideoStream({
    required this.url,
    this.headers,
    this.quality = 'Auto',
    this.subtitles = const [],
    this.size,
  });

  VideoStream copyWith({
    String? url,
    Map<String, String>? headers,
    String? quality,
    List<SubtitleTrack>? subtitles,
    String? size,
  }) {
    return VideoStream(
      url: url ?? this.url,
      headers: headers ?? this.headers,
      quality: quality ?? this.quality,
      subtitles: subtitles ?? this.subtitles,
      size: size ?? this.size,
    );
  }
}

class SubtitleTrack {
  final String url;
  final String language;

  const SubtitleTrack({required this.url, required this.language});

  static const none = SubtitleTrack(url: '', language: 'Off');
}

class AudioTrack {
  final String id;
  final String label;
  final String? language;

  const AudioTrack({required this.id, required this.label, this.language});

  static const auto = AudioTrack(id: 'auto', label: 'Auto');
  static const none = AudioTrack(id: 'no', label: 'Off');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioTrack &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label;

  @override
  int get hashCode => id.hashCode ^ label.hashCode;
}
