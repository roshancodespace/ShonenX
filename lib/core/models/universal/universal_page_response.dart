class UniversalPageResponse<T> {
  final List<T> data;
  final UniversalPageInfo pageInfo;

  const UniversalPageResponse({
    required this.data,
    required this.pageInfo,
  });

  factory UniversalPageResponse.empty() {
    return const UniversalPageResponse(
      data: [],
      pageInfo: UniversalPageInfo(
        currentPage: 1,
        hasNextPage: false,
        lastPage: 1,
        perPage: 0,
        total: 0,
      ),
    );
  }
}

class UniversalPageInfo {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;

  const UniversalPageInfo({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.hasNextPage,
  });
}
