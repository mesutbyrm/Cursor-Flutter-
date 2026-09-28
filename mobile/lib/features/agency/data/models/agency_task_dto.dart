import '../../domain/entities/agency_task_entity.dart';

class AgencyTaskDTO {
  final String id;
  final String agencyId;
  final String title;
  final String description;
  final String taskType;
  final int reward;
  final DateTime dueDate;
  final String status;
  final int progress;
  final List<String> assignedTo;
  final DateTime createdAt;
  final String? completionProof;

  AgencyTaskDTO({
    required this.id,
    required this.agencyId,
    required this.title,
    required this.description,
    required this.taskType,
    required this.reward,
    required this.dueDate,
    required this.status,
    required this.progress,
    required this.assignedTo,
    required this.createdAt,
    this.completionProof,
  });

  factory AgencyTaskDTO.fromJson(Map<String, dynamic> json) {
    return AgencyTaskDTO(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      agencyId: json['agencyId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      taskType: json['taskType']?.toString() ?? 'general',
      reward: (json['reward'] as num?)?.toInt() ?? 0,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'].toString())
          : DateTime.now().add(const Duration(days: 7)),
      status: json['status']?.toString() ?? 'active',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      assignedTo: List<String>.from(
        (json['assignedTo'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      completionProof: json['completionProof']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'agencyId': agencyId,
        'title': title,
        'description': description,
        'taskType': taskType,
        'reward': reward,
        'dueDate': dueDate.toIso8601String(),
        'status': status,
        'progress': progress,
        'assignedTo': assignedTo,
        'createdAt': createdAt.toIso8601String(),
        'completionProof': completionProof,
      };

  AgencyTask toDomain() => AgencyTask(
        id: id,
        agencyId: agencyId,
        title: title,
        description: description,
        taskType: taskType,
        reward: reward,
        dueDate: dueDate,
        status: status,
        progress: progress,
        assignedTo: assignedTo,
        createdAt: createdAt,
        completionProof: completionProof,
      );
}

class AgencyMemberDTO {
  final String id;
  final String agencyId;
  final String userId;
  final String username;
  final String role;
  final int earnings;
  final int referrals;
  final bool isActive;
  final DateTime joinedAt;
  final String? avatarUrl;

  AgencyMemberDTO({
    required this.id,
    required this.agencyId,
    required this.userId,
    required this.username,
    required this.role,
    required this.earnings,
    required this.referrals,
    required this.isActive,
    required this.joinedAt,
    this.avatarUrl,
  });

  factory AgencyMemberDTO.fromJson(Map<String, dynamic> json) {
    return AgencyMemberDTO(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      agencyId: json['agencyId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? 'member',
      earnings: (json['earnings'] as num?)?.toInt() ?? 0,
      referrals: (json['referrals'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] == true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'].toString())
          : DateTime.now(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'agencyId': agencyId,
        'userId': userId,
        'username': username,
        'role': role,
        'earnings': earnings,
        'referrals': referrals,
        'isActive': isActive,
        'joinedAt': joinedAt.toIso8601String(),
        'avatarUrl': avatarUrl,
      };

  AgencyMember toDomain() => AgencyMember(
        id: id,
        agencyId: agencyId,
        userId: userId,
        username: username,
        role: role,
        earnings: earnings,
        referrals: referrals,
        isActive: isActive,
        joinedAt: joinedAt,
        avatarUrl: avatarUrl,
      );
}
