class PageResult<T> {
  const PageResult(this.items, this.page, this.totalPages, this.totalItems);
  final List<T> items;
  final int page, totalPages, totalItems;
  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final pagination = json['pagination'] as Map;
    return PageResult(
      (json['data'] as List)
          .map((item) => parse(Map<String, dynamic>.from(item as Map)))
          .toList(),
      pagination['page'] as int,
      pagination['totalPages'] as int,
      pagination['totalItems'] as int,
    );
  }
}
