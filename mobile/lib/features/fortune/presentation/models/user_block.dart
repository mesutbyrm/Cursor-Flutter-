class UserBlock {
  final String id;
  final String userId;
  final String blockedUserId;
  final String? reason;
  final DateTime createdAt;

  UserBlock({
    required this.id,
    required this.userId,
    required this.blockedUserId,
    this.reason,
    required this.createdAt,
  });

  UserBlock copyWith({
    String? id,
    String? userId,
    String? blockedUserId,
    String? reason,
    DateTime? createdAt,
  }) {
    return UserBlock(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      blockedUserId: blockedUserId ?? this.blockedUserId,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
