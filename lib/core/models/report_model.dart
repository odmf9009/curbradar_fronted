class ReportModel {
  final String id;
  final String objectId;
  final String reportedByUserId;
  final String reason;
  final String description;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.objectId,
    required this.reportedByUserId,
    required this.reason,
    required this.description,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      objectId: json['objectId']?.toString() ?? '',
      reportedByUserId: json['reportedByUserId'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'reportedByUserId': reportedByUserId,
      'reason': reason,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
