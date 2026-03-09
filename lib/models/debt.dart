
enum DebtType { oweMe, iOwe } // oweMe = I am owed, iOwe = I owe someone

class Debt {
  final String id;
  final String userId;
  final String personName;
  final double amount;
  final DebtType type;
  final DateTime dueDate;
  final bool isSettled;
  final String? note;

  Debt({
    required this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    required this.type,
    required this.dueDate,
    this.isSettled = false,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'personName': personName,
    'amount': amount,
    'type': type.name,
    'dueDate': dueDate.toIso8601String(),
    'isSettled': isSettled,
    'note': note,
  };

  factory Debt.fromMap(Map<String, dynamic> map) => Debt(
    id: map['id'],
    userId: map['userId'],
    personName: map['personName'],
    amount: (map['amount'] ?? 0.0).toDouble(),
    type: DebtType.values.byName(map['type']),
    dueDate: DateTime.parse(map['dueDate']),
    isSettled: map['isSettled'] ?? false,
    note: map['note'],
  );
}
