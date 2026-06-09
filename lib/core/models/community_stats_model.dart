class CommunityStats {
  final int activeObjects;
  final int totalCollected;
  final int activeUsers30d;
  final int objectsToday;
  final Map<String, double> categoryDistribution;
  final List<AreaActivity> hottestAreas;
  final EnvironmentalImpact environmentalImpact;

  CommunityStats({
    required this.activeObjects,
    required this.totalCollected,
    required this.activeUsers30d,
    required this.objectsToday,
    required this.categoryDistribution,
    required this.hottestAreas,
    required this.environmentalImpact,
  });

  factory CommunityStats.fromJson(Map<String, dynamic> json) {
    final catDist = <String, double>{};
    final rawCat = json['categoryDistribution'] as Map<String, dynamic>? ?? {};
    rawCat.forEach((k, v) => catDist[k] = (v as num).toDouble());

    return CommunityStats(
      activeObjects: json['activeObjects'] ?? 0,
      totalCollected: json['totalCollected'] ?? json['totalObjectsReused'] ?? 0,
      activeUsers30d: json['activeUsers30d'] ?? 0,
      objectsToday: json['objectsToday'] ?? 0,
      categoryDistribution: catDist,
      hottestAreas: (json['hottestAreas'] as List<dynamic>? ?? [])
          .map((e) => AreaActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      environmentalImpact: EnvironmentalImpact.fromJson(
        json['environmentalImpact'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class AreaActivity {
  final String name;
  final int objectCount;
  final double latitude;
  final double longitude;

  AreaActivity({
    required this.name,
    required this.objectCount,
    required this.latitude,
    required this.longitude,
  });

  factory AreaActivity.fromJson(Map<String, dynamic> json) {
    return AreaActivity(
      name: json['name'] ?? '',
      objectCount: json['objectCount'] ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EnvironmentalImpact {
  final int objectsRecovered;
  final double estimatedWeightKg;
  final double co2SavedKg;

  EnvironmentalImpact({
    required this.objectsRecovered,
    required this.estimatedWeightKg,
    required this.co2SavedKg,
  });

  factory EnvironmentalImpact.fromJson(Map<String, dynamic> json) {
    return EnvironmentalImpact(
      objectsRecovered: json['objectsRecovered'] ?? 0,
      estimatedWeightKg: (json['estimatedWeightKg'] as num?)?.toDouble() ?? 0.0,
      co2SavedKg: (json['co2SavedKg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
