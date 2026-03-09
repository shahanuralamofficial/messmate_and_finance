
class Budget {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final double spent;
  final DateTime month;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    this.spent = 0.0,
    required this.month,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'category': category,
    'amount': amount,
    'spent': spent,
    'month': month.toIso8601String(),
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['id'],
    userId: map['userId'],
    category: map['category'],
    amount: (map['amount'] ?? 0.0).toDouble(),
    spent: (map['spent'] ?? 0.0).toDouble(),
    month: DateTime.parse(map['month']),
  );
}
