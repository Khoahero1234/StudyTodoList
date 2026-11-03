// lib/core/models/study_room_model.dart

class StudyRoomMemberModel {
  final String userId;
  final String name;
  final String avatarUrl;
  final bool isAdmin;
  final DateTime joinedAt;

  const StudyRoomMemberModel({
    required this.userId,
    required this.name,
    this.avatarUrl = '',
    this.isAdmin = false,
    required this.joinedAt,
  });

  factory StudyRoomMemberModel.fromJson(Map<String, dynamic> json) {
    String name = 'Thành viên';
    String avatar = '';
    if (json['user'] is Map<String, dynamic>) {
      final user = json['user'] as Map<String, dynamic>;
      name = user['name']?.toString() ?? name;
      avatar = user['avatarUrl']?.toString() ?? avatar;
    }
    return StudyRoomMemberModel(
      userId: json['userId']?.toString() ?? '',
      name: name,
      avatarUrl: avatar,
      isAdmin: json['isAdmin'] as bool? ?? false,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class StudyRoomModel {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String ownerId;
  final String ownerName;
  final int maxParticipants;
  final bool isPrivate;
  final String inviteCode;
  final String status;
  final List<StudyRoomMemberModel> members;
  final DateTime createdAt;
  final bool isJoined;

  const StudyRoomModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    required this.ownerName,
    required this.maxParticipants,
    this.isPrivate = false,
    required this.inviteCode,
    this.status = 'ACTIVE',
    this.members = const [],
    required this.createdAt,
    this.isJoined = false,
  });

  int get memberCount => members.length;
  bool get isFull => memberCount >= maxParticipants;

  factory StudyRoomModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    List<StudyRoomMemberModel> membersList = [];
    if (json['members'] is List) {
      membersList = (json['members'] as List)
          .map((m) => StudyRoomMemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    String ownerName = 'Chủ phòng';
    if (json['owner'] is Map<String, dynamic>) {
      final ownerObj = json['owner'] as Map<String, dynamic>;
      ownerName = ownerObj['name']?.toString() ?? ownerName;
    }

    final ownerId = json['ownerId']?.toString() ?? '';
    final isJoined = currentUserId != null &&
        (ownerId == currentUserId || membersList.any((m) => m.userId == currentUserId));

    return StudyRoomModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Phòng học',
      description: json['description']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      ownerId: ownerId,
      ownerName: ownerName,
      maxParticipants: json['maxParticipants'] as int? ?? 10,
      isPrivate: json['isPrivate'] as bool? ?? false,
      inviteCode: json['inviteCode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      members: membersList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isJoined: isJoined,
    );
  }
}

