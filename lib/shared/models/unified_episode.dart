class UnifiedEpisode {
  final String id;
  final double number;
  final String? title;
  final bool isFiller;
  final String? thumbnailUrl;

  const UnifiedEpisode({
    required this.id,
    required this.number,
    this.title,
    this.isFiller = false,
    this.thumbnailUrl,
  });
}
