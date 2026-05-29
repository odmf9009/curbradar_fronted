class FilterModel {
  final double distance;
  final String category;
  final String status;
  final String timeRange;
  final String searchQuery;
  final double alertDistance;

  FilterModel({
    this.distance = 10.0,
    this.category = 'Todos',
    this.status = 'available',
    this.timeRange = 'all',
    this.searchQuery = '',
    this.alertDistance = 5.0,
  });

  FilterModel copyWith({
    double? distance,
    String? category,
    String? status,
    String? timeRange,
    String? searchQuery,
    double? alertDistance,
  }) {
    return FilterModel(
      distance: distance ?? this.distance,
      category: category ?? this.category,
      status: status ?? this.status,
      timeRange: timeRange ?? this.timeRange,
      searchQuery: searchQuery ?? this.searchQuery,
      alertDistance: alertDistance ?? this.alertDistance,
    );
  }
}
