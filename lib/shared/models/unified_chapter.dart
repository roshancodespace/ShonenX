class UnifiedChapter {
  final String id;
  final double number;
  final String? title;
  final String? scanlator;

  const UnifiedChapter({
    required this.id, 
    required this.number, 
    this.title, 
    this.scanlator,
  });
}
