class PaginatedResult<T> {
  final List<T> items;
  final bool hasNextPage;

  const PaginatedResult({required this.items, required this.hasNextPage});
}
