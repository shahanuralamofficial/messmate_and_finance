
class MessActionLog {
  final String id;
  final String messId; // The manager's userId
  final String actorId;
  final String actorName;
  final String action; // e.g., 'Added Meal', 'Added Expense'
  final String details;
  final DateTime timestamp;

  MessActionLog({
    required this.id,
    required this.messId,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'messId': messId,
      'actorId': actorId,
      'actorName': actorName,
      'action': action,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessActionLog.fromMap(Map<String, dynamic> map) {
    return MessActionLog(
      id: map['id'],
      messId: map['messId'],
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? 'Unknown',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
