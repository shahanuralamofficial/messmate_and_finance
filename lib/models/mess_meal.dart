
class MessMeal {
  final String id;
  final String userId;
  final String memberId;
  final String? appUserId; // Added to link with app user
  final DateTime date;
  final double count;

  MessMeal({
    required this.id,
    required this.userId,
    required this.memberId,
    this.appUserId,
    required this.date,
    required this.count,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'memberId': memberId,
      'appUserId': appUserId,
      'date': date.toIso8601String(),
      'count': count,
    };
  }

  factory MessMeal.fromMap(Map<String, dynamic> map) {
    return MessMeal(
      id: map['id'],
      userId: map['userId'],
      memberId: map['memberId'],
      appUserId: map['appUserId'],
      date: DateTime.parse(map['date']),
      count: (map['count'] ?? 0.0).toDouble(),
    );
  }
}
