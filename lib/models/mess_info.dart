
import 'package:cloud_firestore/cloud_firestore.dart';

class MessInfo {
  final String id; // This will be the Manager's User ID
  final String name;
  final String address;
  final String ownerPhone;
  final String? logoUrl;
  final DateTime? lastLogoUpdate;

  MessInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.ownerPhone,
    this.logoUrl,
    this.lastLogoUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'ownerPhone': ownerPhone,
      'logoUrl': logoUrl,
      'lastLogoUpdate': lastLogoUpdate != null ? Timestamp.fromDate(lastLogoUpdate!) : null,
    };
  }

  factory MessInfo.fromMap(Map<String, dynamic> map) {
    return MessInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? 'My Mess',
      address: map['address'] ?? 'No Address Provided',
      ownerPhone: map['ownerPhone'] ?? '',
      logoUrl: map['logoUrl'],
      lastLogoUpdate: map['lastLogoUpdate'] != null ? (map['lastLogoUpdate'] as Timestamp).toDate() : null,
    );
  }

  bool canUpdateLogo() {
    if (lastLogoUpdate == null) return true;
    final now = DateTime.now();
    return now.month != lastLogoUpdate!.month || now.year != lastLogoUpdate!.year;
  }
}
