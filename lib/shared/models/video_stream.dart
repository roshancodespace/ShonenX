class VideoStream {
  final String url;
  final Map<String, String>? headers;
  final String quality;
  final List<SubtitleTrack> subtitles;
  final String? size;
  final bool requiresProxy;

  const VideoStream({
    required this.url,
    this.headers,
    this.quality = 'Auto',
    this.subtitles = const [],
    this.size,
    this.requiresProxy = false,
  });

  VideoStream copyWith({
    String? url,
    Map<String, String>? headers,
    String? quality,
    List<SubtitleTrack>? subtitles,
    String? size,
    bool? requiresProxy,
  }) {
    return VideoStream(
      url: url ?? this.url,
      headers: headers ?? this.headers,
      quality: quality ?? this.quality,
      subtitles: subtitles ?? this.subtitles,
      size: size ?? this.size,
      requiresProxy: requiresProxy ?? this.requiresProxy,
    );
  }
}

class SubtitleTrack {
  final String url;
  final String language;
  final String? label;

  const SubtitleTrack({required this.url, required this.language, this.label});

  static const none = SubtitleTrack(url: '', language: 'Off');

  SubtitleTrack copyWith({String? url, String? language, String? label}) {
    return SubtitleTrack(
      url: url ?? this.url,
      language: language ?? this.language,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtitleTrack &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          language == other.language &&
          label == other.label;

  @override
  int get hashCode => url.hashCode ^ language.hashCode ^ label.hashCode;
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
