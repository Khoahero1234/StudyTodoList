// lib/models/user_model.dart

class UserModel {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final String role; // 'admin' | 'customer'
  final bool isActive;
  final bool emailVerified;
  final bool isPremium;
  final int tokenBalance;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoginDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.emailVerified,
    required this.isPremium,
    required this.tokenBalance,
    required this.currentStreak,
    required this.longestStreak,
    this.lastLoginDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'customer',
      isActive: json['isActive'] as bool? ?? true,
      emailVerified: json['emailVerified'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      tokenBalance: json['tokenBalance'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'avatarUrl': avatarUrl,
        'role': role,
        'isActive': isActive,
        'emailVerified': emailVerified,
        'isPremium': isPremium,
        'tokenBalance': tokenBalance,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastLoginDate': lastLoginDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    String? role,
    bool? isActive,
    bool? emailVerified,
    bool? isPremium,
    int? tokenBalance,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      isPremium: isPremium ?? this.isPremium,
      tokenBalance: tokenBalance ?? this.tokenBalance,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
