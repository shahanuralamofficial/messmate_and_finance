class MessHistory {
  final String id;
  final String userId;
  final DateTime date;
  final double totalMeals;
  final double totalMarketCost;
  final double mealRate;
  final List<MemberSnapshot> members;

  MessHistory({
    required this.id,
    required this.userId,
    required this.date,
    required this.totalMeals,
    required this.totalMarketCost,
    required this.mealRate,
    required this.members,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'totalMeals': totalMeals,
      'totalMarketCost': totalMarketCost,
      'mealRate': mealRate,
      'members': members.map((m) => m.toMap()).toList(),
    };
  }

  factory MessHistory.fromMap(Map<String, dynamic> map) {
    return MessHistory(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      totalMeals: (map['totalMeals'] ?? 0.0).toDouble(),
      totalMarketCost: (map['totalMarketCost'] ?? 0.0).toDouble(),
      mealRate: (map['mealRate'] ?? 0.0).toDouble(),
      members: (map['members'] as List?)
              ?.map((m) => MemberSnapshot.fromMap(m))
              .toList() ??
          [],
    );
  }
}

class MemberSnapshot {
  final String memberId;
  final String name;
  final double totalMeals;
  final double totalCost;
  final double totalDue;

  MemberSnapshot({
    required this.memberId,
    required this.name,
    required this.totalMeals,
    required this.totalCost,
    required this.totalDue,
  });

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'name': name,
      'totalMeals': totalMeals,
      'totalCost': totalCost,
      'totalDue': totalDue,
    };
  }

  factory MemberSnapshot.fromMap(Map<String, dynamic> map) {
    return MemberSnapshot(
      memberId: map['memberId'] ?? '',
      name: map['name'] ?? '',
      totalMeals: (map['totalMeals'] ?? 0.0).toDouble(),
      totalCost: (map['totalCost'] ?? 0.0).toDouble(),
      totalDue: (map['totalDue'] ?? 0.0).toDouble(),
    );
  }
}
