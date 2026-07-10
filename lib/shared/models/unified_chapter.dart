class UnifiedChapter {
  final String id;
  final double number;
  final String? title;
  final String? scanlator;
  final String? airDate;
  final String? uploadDate;

  const UnifiedChapter({
    required this.id, 
    required this.number, 
    this.title, 
    this.scanlator,
    this.airDate,
    this.uploadDate,
  });
}
