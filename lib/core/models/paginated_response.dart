class PaginatedResponse<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool isFirst;
  final bool isLast;
  final int numberOfElements;
  final bool isEmpty;

  const PaginatedResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.isFirst,
    required this.isLast,
    required this.numberOfElements,
    required this.isEmpty,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic item) fromJsonT,
  ) {
    final rawContent = json['content'] as List<dynamic>? ?? [];
    final items = rawContent.map((item) => fromJsonT(item)).toList();

    return PaginatedResponse<T>(
      content: items,
      pageNumber: (json['number'] as num?)?.toInt() ?? 0,
      pageSize: (json['size'] as num?)?.toInt() ?? 10,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      isFirst: json['first'] as bool? ?? true,
      isLast: json['last'] as bool? ?? true,
      numberOfElements:
          (json['numberOfElements'] as num?)?.toInt() ?? items.length,
      isEmpty: json['empty'] as bool? ?? items.isEmpty,
    );
  }
}
