class MessMember {
  final String id;
  final String userId; // The Manager's ID
  final String messId; // The ID of the mess this member belongs to
  final String? appUserId; // If the member is also an app user, their UID
  final String name;
  final String? email; // For connecting with app users
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
  final String paymentStatus; // 'unpaid', 'pending', 'confirmed'
  final String? paymentMethod; // 'Cash', 'bKash', etc.
  
  final bool isManager;
  final bool isAppUser;

  MessMember({
    required this.id,
    required this.userId,
    required this.messId,
    this.appUserId,
    required this.name,
    this.email,
    this.initialDeposit = 0.0,
    this.totalMeals = 0.0,
    this.totalMarketCost = 0.0,
    this.monthlyRent = 0.0,
    this.wifiBill = 0.0,
    this.electricityBill = 0.0,
    this.otherBills = 0.0,
    this.previousDue = 0.0,
    this.isPaid = false,
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.isManager = false,
    this.isAppUser = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'messId': messId,
      'appUserId': appUserId,
      'name': name,
      'email': email,
      'initialDeposit': initialDeposit,
      'totalMeals': totalMeals,
      'totalMarketCost': totalMarketCost,
      'monthlyRent': monthlyRent,
      'wifiBill': wifiBill,
      'electricityBill': electricityBill,
      'otherBills': otherBills,
      'previousDue': previousDue,
      'isPaid': isPaid,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'isManager': isManager,
      'isAppUser': isAppUser,
    };
  }

  factory MessMember.fromMap(Map<String, dynamic> map) {
    return MessMember(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      messId: map['messId'] ?? '',
      appUserId: map['appUserId'],
      name: map['name'] ?? '',
      email: map['email'],
      initialDeposit: (map['initialDeposit'] ?? 0.0).toDouble(),
      totalMeals: (map['totalMeals'] ?? 0.0).toDouble(),
      totalMarketCost: (map['totalMarketCost'] ?? 0.0).toDouble(),
      monthlyRent: (map['monthlyRent'] ?? 0.0).toDouble(),
      wifiBill: (map['wifiBill'] ?? 0.0).toDouble(),
      electricityBill: (map['electricityBill'] ?? 0.0).toDouble(),
      otherBills: (map['otherBills'] ?? 0.0).toDouble(),
      previousDue: (map['previousDue'] ?? 0.0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      paymentMethod: map['paymentMethod'],
      isManager: map['isManager'] ?? false,
      isAppUser: map['isAppUser'] ?? false,
    );
  }

  MessMember copyWith({
    String? name,
    String? email,
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
    String? userId,
    String? messId,
    String? paymentStatus,
    String? paymentMethod,
  }) {
    return MessMember(
      id: id,
      userId: userId ?? this.userId,
      messId: messId ?? this.messId,
      appUserId: appUserId ?? this.appUserId,
      name: name ?? this.name,
      email: email ?? this.email,
      initialDeposit: initialDeposit ?? this.initialDeposit,
      totalMeals: totalMeals ?? this.totalMeals,
      totalMarketCost: totalMarketCost ?? this.totalMarketCost,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      wifiBill: wifiBill ?? this.wifiBill,
      electricityBill: electricityBill ?? this.electricityBill,
      otherBills: otherBills ?? this.otherBills,
      previousDue: previousDue ?? this.previousDue,
      isPaid: isPaid ?? this.isPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isManager: isManager ?? this.isManager,
      isAppUser: isAppUser ?? this.isAppUser,
    );
  }
}
