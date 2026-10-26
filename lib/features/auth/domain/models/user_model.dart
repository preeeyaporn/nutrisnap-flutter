/// User model for Firebase Auth and user profile.
class UserModel {
  final String id;
  final String? email;
  final String displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final double dailyCalorieTarget;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.email,
    required this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.dailyCalorieTarget = 2000.0,
    required this.createdAt,
  });

  String get name => displayName;

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    double? dailyCalorieTarget,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,
      'dailyCalorieTarget': dailyCalorieTarget,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString(),
      displayName: map['displayName']?.toString() ?? 'ผู้ใช้งาน NutriSnap',
      photoUrl: map['photoUrl']?.toString(),
      isAnonymous: map['isAnonymous'] == true,
      dailyCalorieTarget:
          (map['dailyCalorieTarget'] as num?)?.toDouble() ?? 2000.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static UserModel guest() {
    return UserModel(
      id: 'guest_user',
      displayName: 'ผู้ใช้ทั่วไป',
      isAnonymous: true,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime.now(),
    );
  }
}
