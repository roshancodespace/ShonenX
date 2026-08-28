class EpisodeMetadata {
  final double number;
  final String? title;
  final String? japaneseTitle;
  final String? romanjiTitle;
  final String? description;
  final String? thumbnailUrl;
  final String? airDate;
  final bool? isFiller;
  final double? score;

  const EpisodeMetadata({
    required this.number,
    this.title,
    this.japaneseTitle,
    this.romanjiTitle,
    this.description,
    this.thumbnailUrl,
    this.airDate,
    this.isFiller,
    this.score,
  });

  EpisodeMetadata copyWith({
    double? number,
    String? title,
    String? japaneseTitle,
    String? romanjiTitle,
    String? description,
    String? thumbnailUrl,
    String? airDate,
    bool? isFiller,
    double? score,
  }) {
    return EpisodeMetadata(
      number: number ?? this.number,
      title: title ?? this.title,
      japaneseTitle: japaneseTitle ?? this.japaneseTitle,
      romanjiTitle: romanjiTitle ?? this.romanjiTitle,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      airDate: airDate ?? this.airDate,
      isFiller: isFiller ?? this.isFiller,
      score: score ?? this.score,
    );
  }

  EpisodeMetadata merge(EpisodeMetadata other) {
    return EpisodeMetadata(
      number: number,
      title: (other.title != null && other.title!.isNotEmpty) ? other.title : title,
      japaneseTitle: (other.japaneseTitle != null && other.japaneseTitle!.isNotEmpty) ? other.japaneseTitle : japaneseTitle,
      romanjiTitle: (other.romanjiTitle != null && other.romanjiTitle!.isNotEmpty) ? other.romanjiTitle : romanjiTitle,
      description: (other.description != null && other.description!.isNotEmpty) ? other.description : description,
      thumbnailUrl: (other.thumbnailUrl != null && other.thumbnailUrl!.isNotEmpty) ? other.thumbnailUrl : thumbnailUrl,
      airDate: (other.airDate != null && other.airDate!.isNotEmpty) ? other.airDate : airDate,
      isFiller: other.isFiller ?? isFiller,
      score: other.score ?? score,
    );
  }
}
