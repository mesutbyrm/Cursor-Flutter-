class AgencyTask {
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

  AgencyTask({
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

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != 'completed';

  bool get isCompleted => status == 'completed';

  bool get isActive => status == 'active';

  int get daysRemaining =>
      dueDate.difference(DateTime.now()).inDays;
}

class AgencyMember {
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

  AgencyMember({
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

  bool get isManager => role == 'manager' || role == 'admin';

  bool get isAdmin => role == 'admin';

  int get totalValue => earnings + (referrals * 100);
}
