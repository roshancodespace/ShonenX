import 'package:shonenx/core_mangayomi/eval/javascript/http.dart';

class Video {
  String url;
  String quality;
  String originalUrl;
  Map<String, String>? headers;
  List<Track>? subtitles;
  List<Track>? audios;
  bool? isM3u8;
  String? format;

  Video(
    this.url,
    this.quality,
    this.originalUrl, {
    this.headers,
    this.subtitles,
    this.audios,
    this.isM3u8 = false,
    this.format,
  });
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      json['url'].toString().trim(),
      json['quality'].toString().trim(),
      json['originalUrl'].toString().trim(),
      headers: (json['headers'] as Map?)?.toMapStringString,
      subtitles: json['subtitles'] != null
          ? (json['subtitles'] as List).map((e) => Track.fromJson(e)).toList()
          : [],
      audios: json['audios'] != null
          ? (json['audios'] as List).map((e) => Track.fromJson(e)).toList()
          : [],
      isM3u8: json['isM3u8'] as bool?,
      format: json['format']?.toString().trim(),
    );
  }
  Map<String, dynamic> toJson() => {
    'url': url,
    'quality': quality,
    'originalUrl': originalUrl,
    'headers': headers,
    'subtitles': subtitles?.map((e) => e.toJson()).toList(),
    'audios': audios?.map((e) => e.toJson()).toList(),
    'isM3u8': isM3u8,
    'format': format,
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
