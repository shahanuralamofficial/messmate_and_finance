enum MealPlanStatus { pending, approved, rejected }

class MessMealPlan {
  final String id;
  final String messId;
  final String memberId;
  final String memberName;
  final DateTime date;
  final bool isEnabled; // meal on or off requested
  final MealPlanStatus status;

  MessMealPlan({
    required this.id,
    required this.messId,
    required this.memberId,
    required this.memberName,
    required this.date,
    this.isEnabled = true,
    this.status = MealPlanStatus.approved, // Default to approved for manager's action
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'messId': messId,
      'memberId': memberId,
      'memberName': memberName,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'isEnabled': isEnabled,
      'status': status.name,
    };
  }

  factory MessMealPlan.fromMap(Map<String, dynamic> map) {
    return MessMealPlan(
      id: map['id'],
      messId: map['messId'],
      memberId: map['memberId'],
      memberName: map['memberName'] ?? 'Unknown',
      date: DateTime.parse(map['date']),
      isEnabled: map['isEnabled'] ?? true,
      status: MealPlanStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'approved'),
        orElse: () => MealPlanStatus.approved,
      ),
    );
  }

  MessMealPlan copyWith({
    MealPlanStatus? status,
    bool? isEnabled,
  }) {
    return MessMealPlan(
      id: id,
      messId: messId,
      memberId: memberId,
      memberName: memberName,
      date: date,
      isEnabled: isEnabled ?? this.isEnabled,
      status: status ?? this.status,
    );
  }
}
