import 'package:equatable/equatable.dart';

/// canlifal.com `GET /api/agency/my` yanıtı.
class AgencyEntity extends Equatable {
  const AgencyEntity({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.applicationStatus,
    this.memberCount = 0,
    this.totalEarnings = 0,
    this.pendingEarnings = 0,
    this.ownerUserId,
    this.inviteCode,
    this.isActive = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? applicationStatus;
  final int memberCount;
  final int totalEarnings;
  final int pendingEarnings;
  final String? ownerUserId;
  final String? inviteCode;
  final bool isActive;

  bool get isApproved {
    final status = applicationStatus?.trim().toLowerCase();
    if (status == null || status.isEmpty) return isActive && id.isNotEmpty;
    const approved = {'approved', 'active'};
    if (approved.contains(status)) return true;
    const pending = {'pending', 'rejected', 'declined'};
    if (pending.contains(status)) return false;
    return isActive && id.isNotEmpty;
  }

  /// Kullanılabilir ajans — onaylı veya aktif kayıt.
  bool get isUsable => id.isNotEmpty && (isApproved || isActive);

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        logoUrl,
        applicationStatus,
        memberCount,
        totalEarnings,
        pendingEarnings,
        ownerUserId,
        inviteCode,
        isActive,
      ];
}

class AgencyMemberEntity extends Equatable {
  const AgencyMemberEntity({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role,
    this.earnings = 0,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? role;
  final int earnings;
  final bool isOnline;

  @override
  List<Object?> get props => [id, name, avatarUrl, role, earnings, isOnline];
}

class AgencyEarningEntity extends Equatable {
  const AgencyEarningEntity({
    required this.id,
    required this.amount,
    this.source,
    this.createdAt,
    this.memberName,
  });

  final String id;
  final int amount;
  final String? source;
  final DateTime? createdAt;
  final String? memberName;

  @override
  List<Object?> get props => [id, amount, source, createdAt, memberName];
}

class AgencyTaskEntity extends Equatable {
  const AgencyTaskEntity({
    required this.id,
    required this.title,
    this.description,
    this.reward = 0,
    this.completed = false,
    this.deadline,
  });

  final String id;
  final String title;
  final String? description;
  final int reward;
  final bool completed;
  final DateTime? deadline;

  @override
  List<Object?> get props =>
      [id, title, description, reward, completed, deadline];
}
