
class MessMealPlan {
  final String id;
  final String messId;
  final String memberId;
  final DateTime date;
  final bool isEnabled; // meal on or off
  final double count; // how many meals if enabled (default usually 1 or 2)

  MessMealPlan({
    required this.id,
    required this.messId,
    required this.memberId,
    required this.date,
    this.isEnabled = true,
    this.count = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'messId': messId,
      'memberId': memberId,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'isEnabled': isEnabled,
      'count': count,
    };
  }

  factory MessMealPlan.fromMap(Map<String, dynamic> map) {
    return MessMealPlan(
      id: map['id'],
      messId: map['messId'],
      memberId: map['memberId'],
      date: DateTime.parse(map['date']),
      isEnabled: map['isEnabled'] ?? true,
      count: (map['count'] ?? 1.0).toDouble(),
    );
  }
}
