import 'package:cloud_firestore/cloud_firestore.dart';

class Planning {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final double targetAmount;
  final double periodicAmount; // Amount to pay per week/month
  final String collectionType; // 'Weekly' or 'Monthly'
  final DateTime createdAt;
  final bool isCompleted;

  Planning({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.targetAmount,
    this.periodicAmount = 0.0,
    this.collectionType = 'Monthly',
    required this.createdAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'targetAmount': targetAmount,
      'periodicAmount': periodicAmount,
      'collectionType': collectionType,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Planning.fromMap(Map<String, dynamic> map) {
    return Planning(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
      periodicAmount: (map['periodicAmount'] ?? 0.0).toDouble(),
      collectionType: map['collectionType'] ?? 'Monthly',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class PlanningMember {
  final String userId;
  final String name;
  final String email;
  final double contributedAmount;
  final bool hasPaid; // Used for marking if they contributed in a specific period/round

  PlanningMember({
    required this.userId,
    required this.name,
    required this.email,
    this.contributedAmount = 0.0,
    this.hasPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'contributedAmount': contributedAmount,
      'hasPaid': hasPaid,
    };
  }

  factory PlanningMember.fromMap(Map<String, dynamic> map) {
    return PlanningMember(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      contributedAmount: (map['contributedAmount'] ?? 0.0).toDouble(),
      hasPaid: map['hasPaid'] ?? false,
    );
  }
}
