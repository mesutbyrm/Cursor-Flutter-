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

  /// Kullanılabilir ajans — `my` kaydı varsa onaylı say (pending/rejected hariç).
  bool get isUsable {
    if (id.trim().isEmpty) return false;
    if (isApproved) return true;
    final status = applicationStatus?.trim().toLowerCase();
    if (status == 'pending' || status == 'rejected' || status == 'declined') {
      return false;
    }
    return true;
  }

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

/// `GET /api/agency/tasks` — haftalık ajans hedefi (Prisma `AgencyTask`).
class AgencyWeeklyTask extends Equatable {
  const AgencyWeeklyTask({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.earningsTarget,
    required this.earningsActual,
    required this.newUsersTarget,
    required this.newUsersActual,
    required this.activeUsersTarget,
    required this.activeUsersActual,
    required this.completionPercent,
    required this.bonusAwarded,
    required this.status,
  });

  final String id;
  final DateTime? weekStart;
  final DateTime? weekEnd;
  final double earningsTarget;
  final double earningsActual;
  final int newUsersTarget;
  final int newUsersActual;
  final int activeUsersTarget;
  final int activeUsersActual;
  final double completionPercent;
  final double bonusAwarded;
  final String status;

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  static int _int(dynamic v) => _num(v).round();

  factory AgencyWeeklyTask.fromJson(Map<String, dynamic> json) =>
      AgencyWeeklyTask(
        id: json['id']?.toString() ?? '',
        weekStart: DateTime.tryParse(json['weekStart']?.toString() ?? ''),
        weekEnd: DateTime.tryParse(json['weekEnd']?.toString() ?? ''),
        earningsTarget: _num(json['earningsTarget']),
        earningsActual: _num(json['earningsActual']),
        newUsersTarget: _int(json['newUsersTarget']),
        newUsersActual: _int(json['newUsersActual']),
        activeUsersTarget: _int(json['activeUsersTarget']),
        activeUsersActual: _int(json['activeUsersActual']),
        completionPercent: _num(json['completionPercent']),
        bonusAwarded: _num(json['bonusAwarded']),
        status: json['status']?.toString() ?? 'active',
      );

  @override
  List<Object?> get props => [
        id,
        weekStart,
        earningsActual,
        newUsersActual,
        activeUsersActual,
        completionPercent,
        status,
      ];
}

class AgencyWeeklyTasks {
  const AgencyWeeklyTasks({required this.current, required this.past});

  final AgencyWeeklyTask? current;
  final List<AgencyWeeklyTask> past;

  factory AgencyWeeklyTasks.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final cur = data['currentTask'];
    final past = data['pastTasks'];
    return AgencyWeeklyTasks(
      current: cur is Map
          ? AgencyWeeklyTask.fromJson(Map<String, dynamic>.from(cur))
          : null,
      past: past is List
          ? past
              .whereType<Map>()
              .map((e) => AgencyWeeklyTask.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// `GET /api/agency/applications` — bekleyen üye / çıkış talepleri.
class AgencyMemberApplicationEntity extends Equatable {
  const AgencyMemberApplicationEntity({
    required this.id,
    required this.type,
    required this.status,
    required this.userId,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.reason,
    this.createdAt,
  });

  final String id;
  final String type;
  final String status;
  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String? reason;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        type,
        status,
        userId,
        displayName,
        username,
        avatarUrl,
        reason,
        createdAt,
      ];
}
