// lib/core/models/friend_model.dart

class FriendModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isOnline;

  const FriendModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isOnline = false,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Người dùng',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}

class FriendRequestModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String? requesterAvatar;
  final String status;
  final DateTime createdAt;

  const FriendRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    this.requesterAvatar,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    String name = 'Người dùng';
    String email = '';
    String? avatar;
    if (json['requester'] is Map<String, dynamic>) {
      final req = json['requester'] as Map<String, dynamic>;
      name = req['name']?.toString() ?? name;
      email = req['email']?.toString() ?? email;
      avatar = req['avatarUrl']?.toString();
    }
    return FriendRequestModel(
      id: json['id']?.toString() ?? '',
      requesterId: json['requesterId']?.toString() ?? '',
      requesterName: name,
      requesterEmail: email,
      requesterAvatar: avatar,
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class UserSearchResult {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isFriend;
  final bool isPendingSent;
  final bool isPendingReceived;

  const UserSearchResult({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isFriend = false,
    this.isPendingSent = false,
    this.isPendingReceived = false,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Người dùng',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      isFriend: json['isFriend'] as bool? ?? false,
      isPendingSent: json['isPendingSent'] as bool? ?? false,
      isPendingReceived: json['isPendingReceived'] as bool? ?? false,
    );
  }
}

