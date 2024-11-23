// Model for the Episode Streaming Links response
class EpisodeStreamingLinksModel {
  final List<Source> sources;
  final List<Track>? tracks;
  final IntroOutro? intro;
  final IntroOutro? outro;
  final int? anilistID;
  final int? malID;

  EpisodeStreamingLinksModel({
    required this.sources,
    this.tracks,
    this.intro,
    this.outro,
    this.anilistID,
    this.malID,
  });

  factory EpisodeStreamingLinksModel.fromJson(Map<String, dynamic> json) {
    return EpisodeStreamingLinksModel(
      sources: (json['data']['sources'] as List)
          .map((e) => Source.fromJson(e))
          .toList(),
      tracks: json['data']['tracks'] != null
          ? (json['data']['tracks'] as List)
              .map((e) => Track.fromJson(e))
              .toList()
          : null,
      intro: json['data']['intro'] != null
          ? IntroOutro.fromJson(json['data']['intro'])
          : null,
      outro: json['data']['outro'] != null
          ? IntroOutro.fromJson(json['data']['outro'])
          : null,
      anilistID: json['data']['anilistID'],
      malID: json['data']['malID'],
    );
  }
}

// Model for a source (streaming link)
class Source {
  final String url;
  final String type;

  Source({
    required this.url,
    required this.type,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      url: json['url'],
      type: json['type'],
    );
  }
}

// Model for a track (e.g., thumbnail track)
class Track {
  final String file;
  final String kind;
  final String? label;
  final bool? isDefault;

  Track({
    required this.file,
    required this.kind,
    required this.label,
    required this.isDefault
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      file: json['file'],
      kind: json['kind'],
      label: json['label'],
      isDefault: json['default']
    );
  }
}

// Model for intro/outro segments
class IntroOutro {
  final int start;
  final int end;

  IntroOutro({
    required this.start,
    required this.end,
  });

  factory IntroOutro.fromJson(Map<String, dynamic> json) {
    return IntroOutro(
      start: json['start'],
      end: json['end'],
    );
  }
}
