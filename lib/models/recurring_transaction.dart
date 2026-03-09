
enum RecurringInterval { daily, weekly, monthly, yearly }

class RecurringTransaction {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final RecurringInterval interval;
  final DateTime nextDate;
  final bool isActive;

  RecurringTransaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.interval,
    required this.nextDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'amount': amount,
    'category': category,
    'interval': interval.name,
    'nextDate': nextDate.toIso8601String(),
    'isActive': isActive,
  };

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) => RecurringTransaction(
    id: map['id'],
    userId: map['userId'],
    title: map['title'],
    amount: (map['amount'] ?? 0.0).toDouble(),
    category: map['category'],
    interval: RecurringInterval.values.byName(map['interval']),
    nextDate: DateTime.parse(map['nextDate']),
    isActive: map['isActive'] ?? true,
  );
}
