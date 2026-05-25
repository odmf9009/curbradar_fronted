class FilterModel {
  final double distance;
  final String category;
  final String status;
  final String timeRange;
  final String searchQuery;

  FilterModel({
    this.distance = 10.0,
    this.category = 'Todos',
    this.status = 'available',
    this.timeRange = 'all',
    this.searchQuery = '',
  });

  FilterModel copyWith({
    double? distance,
    String? category,
    String? status,
    String? timeRange,
    String? searchQuery,
  }) {
    return FilterModel(
      distance: distance ?? this.distance,
      category: category ?? this.category,
      status: status ?? this.status,
      timeRange: timeRange ?? this.timeRange,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
