import 'package:shonenx/shared/models/unified_chapter.dart';

class UnifiedEpisode {
  final String id;
  final double number;
  final int? season;
  final String? title;
  final bool isFiller;
  final String? thumbnailUrl;
  final String? airDate;
  final String? uploadDate;
  final String? scanlator;

  const UnifiedEpisode({
    required this.id,
    required this.number,
    this.season,
    this.title,
    this.isFiller = false,
    this.thumbnailUrl,
    this.scanlator,
    this.airDate,
    this.uploadDate,
  });

  factory UnifiedEpisode.fromChapter(UnifiedChapter chapter) {
    return UnifiedEpisode(
      id: chapter.id,
      number: chapter.number,
      season: null,
      title: chapter.title,
      scanlator: chapter.scanlator,
      airDate: chapter.airDate,
      uploadDate: chapter.uploadDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'season': season,
      'title': title,
      'isFiller': isFiller,
      'thumbnailUrl': thumbnailUrl,
      'airDate': airDate,
      'uploadDate': uploadDate,
      'scanlator': scanlator,
    };
  }
}
