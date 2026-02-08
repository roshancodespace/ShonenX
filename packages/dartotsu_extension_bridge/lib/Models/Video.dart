class Video {
  String? title;
  String url;
  String quality;
  Map<String, String>? headers;
  List<Track>? subtitles;
  List<Track>? audios;

  Video(
    this.title,
    this.url,
    this.quality, {
    this.headers,
    this.subtitles,
    this.audios,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      json['title'].toString().trim(),
      json['url'].toString().trim(),
      json['quality'].toString().trim(),
      headers: (json['headers'] as Map?)?.cast<String, String>(),
      subtitles: json['subtitles'] != null
          ? (json['subtitles'] as List)
                .map((e) => Track.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : [],
      audios: json['audios'] != null
          ? (json['audios'] as List)
                .map((e) => Track.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'quality': quality,
    'headers': headers,
    'subtitles': subtitles?.map((e) => e.toJson()).toList(),
    'audios': audios?.map((e) => e.toJson()).toList(),
  };
}

class Track {
  String? file;
  String? label;

  Track({this.file, this.label});

  Track.fromJson(Map<String, dynamic> json) {
    file = json['file']?.toString().trim();
    label = json['label']?.toString().trim();
  }

  Map<String, dynamic> toJson() => {'file': file, 'label': label};
}