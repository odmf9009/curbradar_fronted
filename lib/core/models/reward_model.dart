class RewardItem {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpRequired;
  final bool isRedeemed;
  final bool canAfford;

  RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpRequired,
    this.isRedeemed = false,
    this.canAfford = false,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🎁',
      xpRequired: json['xpRequired'] ?? 0,
      isRedeemed: json['isRedeemed'] ?? false,
      canAfford: json['canAfford'] ?? false,
    );
  }
}

class XPTransaction {
  final String id;
  final String title;
  final int xpAmount;
  final DateTime date;

  XPTransaction({
    required this.id,
    required this.title,
    required this.xpAmount,
    required this.date,
  });

  factory XPTransaction.fromJson(Map<String, dynamic> json) {
    return XPTransaction(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      xpAmount: json['xpAmount'] ?? 0,
      date: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
