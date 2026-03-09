
class SavingsGoal {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final bool isCompleted;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'deadline': deadline.toIso8601String(),
    'isCompleted': isCompleted,
  };

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
    id: map['id'],
    userId: map['userId'],
    title: map['title'],
    targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
    currentAmount: (map['currentAmount'] ?? 0.0).toDouble(),
    deadline: DateTime.parse(map['deadline']),
    isCompleted: map['isCompleted'] ?? false,
  );
}
