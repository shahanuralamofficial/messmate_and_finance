
class MessMember {
  final String id;
  final String userId; // The Mess Manager's ID
  final String? appUserId; // If the member is also an app user, their UID
  final String name;
  final double initialDeposit;
  final double totalMeals;
  final double totalMarketCost;
  
  // New Bill Fields
  final double monthlyRent;
  final double wifiBill;
  final double electricityBill;
  final double otherBills;
  final double previousDue;
  final bool isPaid;
  
  final bool isManager;
  final bool isAppUser;

  MessMember({
    required this.id,
    required this.userId,
    this.appUserId,
    required this.name,
    this.initialDeposit = 0.0,
    this.totalMeals = 0.0,
    this.totalMarketCost = 0.0,
    this.monthlyRent = 0.0,
    this.wifiBill = 0.0,
    this.electricityBill = 0.0,
    this.otherBills = 0.0,
    this.previousDue = 0.0,
    this.isPaid = false,
    this.isManager = false,
    this.isAppUser = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'appUserId': appUserId,
      'name': name,
      'initialDeposit': initialDeposit,
      'totalMeals': totalMeals,
      'totalMarketCost': totalMarketCost,
      'monthlyRent': monthlyRent,
      'wifiBill': wifiBill,
      'electricityBill': electricityBill,
      'otherBills': otherBills,
      'previousDue': previousDue,
      'isPaid': isPaid,
      'isManager': isManager,
      'isAppUser': isAppUser,
    };
  }

  factory MessMember.fromMap(Map<String, dynamic> map) {
    return MessMember(
      id: map['id'],
      userId: map['userId'],
      appUserId: map['appUserId'],
      name: map['name'],
      initialDeposit: (map['initialDeposit'] ?? 0.0).toDouble(),
      totalMeals: (map['totalMeals'] ?? 0.0).toDouble(),
      totalMarketCost: (map['totalMarketCost'] ?? 0.0).toDouble(),
      monthlyRent: (map['monthlyRent'] ?? 0.0).toDouble(),
      wifiBill: (map['wifiBill'] ?? 0.0).toDouble(),
      electricityBill: (map['electricityBill'] ?? 0.0).toDouble(),
      otherBills: (map['otherBills'] ?? 0.0).toDouble(),
      previousDue: (map['previousDue'] ?? 0.0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      isManager: map['isManager'] ?? false,
      isAppUser: map['isAppUser'] ?? false,
    );
  }

  MessMember copyWith({
    String? name,
    double? initialDeposit,
    double? totalMeals,
    double? totalMarketCost,
    double? monthlyRent,
    double? wifiBill,
    double? electricityBill,
    double? otherBills,
    double? previousDue,
    bool? isPaid,
    bool? isManager,
    bool? isAppUser,
    String? appUserId,
  }) {
    return MessMember(
      id: id,
      userId: userId,
      appUserId: appUserId ?? this.appUserId,
      name: name ?? this.name,
      initialDeposit: initialDeposit ?? this.initialDeposit,
      totalMeals: totalMeals ?? this.totalMeals,
      totalMarketCost: totalMarketCost ?? this.totalMarketCost,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      wifiBill: wifiBill ?? this.wifiBill,
      electricityBill: electricityBill ?? this.electricityBill,
      otherBills: otherBills ?? this.otherBills,
      previousDue: previousDue ?? this.previousDue,
      isPaid: isPaid ?? this.isPaid,
      isManager: isManager ?? this.isManager,
      isAppUser: isAppUser ?? this.isAppUser,
    );
  }
}
