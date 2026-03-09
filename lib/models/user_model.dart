
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelation;
  final DateTime createdAt;
  final DateTime lastLogin;
  final Map<String, dynamic> settings;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.guardianName,
    this.guardianPhone,
    this.guardianRelation,
    required this.createdAt,
    required this.lastLogin,
    this.settings = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'guardianRelation': guardianRelation,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'settings': settings,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      phoneNumber: map['phoneNumber'],
      guardianName: map['guardianName'],
      guardianPhone: map['guardianPhone'],
      guardianRelation: map['guardianRelation'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin: DateTime.parse(map['lastLogin'] ?? DateTime.now().toIso8601String()),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
    );
  }

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? guardianName,
    String? guardianPhone,
    String? guardianRelation,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      createdAt: createdAt,
      lastLogin: lastLogin,
      settings: settings ?? this.settings,
    );
  }
}
