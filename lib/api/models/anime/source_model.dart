class BaseSourcesModel {
  List<Subtitle> tracks;
  Intro? intro;
  Intro? outro;
  List<Sources> sources;
  int? anilistID;
  int? malID;

  BaseSourcesModel({
    this.tracks = const [],
    this.intro,
    this.outro,
    this.sources = const [],
    this.anilistID,
    this.malID,
  });

  BaseSourcesModel.fromJson(Map<String, dynamic> json)
      : tracks = (json['subtitles'] as List<dynamic>?)
                ?.map((v) => Subtitle.fromJson(v))
                .toList() ??
            [],
        sources = (json['sources'] as List<dynamic>?)
                ?.map((v) => Sources.fromJson(v))
                .toList() ??
            [] {
    intro = json['intro'] != null ? Intro.fromJson(json['intro']) : null;
    outro = json['outro'] != null ? Intro.fromJson(json['outro']) : null;
    anilistID = json['anilistID'];
    malID = json['malID'];
  }
}

class Subtitle {
  String? url;
  String? lang;

  Subtitle({this.url, this.lang});

  Subtitle.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    lang = json['lang'];
  }
}

class Intro {
  int? start;
  int? end;

  Intro({this.start, this.end});

  Intro.fromJson(Map<String, dynamic> json) {
    start = json['start'];
    end = json['end'];
  }
}

class Sources {
  String? url;
  String? type;
  bool isM3U8;
  bool isDub;
  String? quality;

  Sources({
    this.url,
    this.type,
    this.isM3U8 = false,
    this.isDub = false,
    this.quality,
  });

  Sources.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        type = json['type'],
        isM3U8 = json['isM3U8'] ?? false,
        isDub = json['isDub'] ?? false,
        quality = json['quality'] ?? 'Unknown';
}
