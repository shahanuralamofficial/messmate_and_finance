
class MessMarketExpense {
  final String id;
  final String messId; // The manager's userId
  final String memberId;
  final String memberName;
  final double amount;
  final String description;
  final DateTime date;

  MessMarketExpense({
    required this.id,
    required this.messId,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'messId': messId,
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory MessMarketExpense.fromMap(Map<String, dynamic> map) {
    return MessMarketExpense(
      id: map['id'],
      messId: map['messId'],
      memberId: map['memberId'],
      memberName: map['memberName'] ?? 'Unknown',
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }
}
