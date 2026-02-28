
class Account {
  final String id;
  final String userId;
  String name;
  String type;
  double balance;
  String? note;
  DateTime lastUpdated;
  String? icon;
  bool isActive;
  String? color;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.note,
    DateTime? lastUpdated,
    this.icon,
    this.isActive = true,
    this.color,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'note': note,
      'lastUpdated': lastUpdated.toIso8601String(),
      'icon': icon,
      'isActive': isActive,
      'color': color,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      type: map['type'],
      balance: map['balance'].toDouble(),
      note: map['note'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
      icon: map['icon'],
      isActive: map['isActive'] ?? true,
      color: map['color'],
    );
  }

  Account copyWith({
    String? name,
    String? type,
    double? balance,
    String? note,
    DateTime? lastUpdated,
    String? icon,
    bool? isActive,
    String? color,
  }) {
    return Account(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      note: note ?? this.note,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
    );
  }
}