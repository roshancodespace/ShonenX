class BaseSourcesModel {
  dynamic headers;
  List<Subtitle> tracks;
  Intro? intro;
  Intro? outro;
  List<Source> sources;
  int? anilistID;
  int? malID;

  BaseSourcesModel({
    this.headers,
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
                ?.map((v) => Source.fromJson(v))
                .toList() ??
            [] {
    headers = json['headers'];
    intro = json['intro'] != null ? Intro.fromJson(json['intro']) : null;
    outro = json['outro'] != null ? Intro.fromJson(json['outro']) : null;
    anilistID = json['anilistID'];
    malID = json['malID'];
  }
}

class Subtitle {
  String? url;
  String? lang;
  bool? isSub;

  Subtitle({this.url, this.lang, this.isSub = false});

  Subtitle.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    lang = json['lang'];
    isSub = json['isSub'] ?? false;
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

class Source {
  String? url;
  String? type;
  bool isM3U8;
  bool isDub;
  String? quality;

  Source({
    this.url,
    this.type,
    this.isM3U8 = false,
    this.isDub = false,
    this.quality,
  });

  Source.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        type = json['type'],
        isM3U8 = json['isM3U8'] ?? false,
        isDub = json['isDub'] ?? false,
        quality = json['quality'] ?? 'Default';
}
