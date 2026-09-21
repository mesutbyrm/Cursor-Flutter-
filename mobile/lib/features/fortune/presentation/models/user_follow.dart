class UserFollow {
  final String id;
  final String userId;
  final String followerId;
  final DateTime createdAt;

  UserFollow({
    required this.id,
    required this.userId,
    required this.followerId,
    required this.createdAt,
  });

  UserFollow copyWith({
    String? id,
    String? userId,
    String? followerId,
    DateTime? createdAt,
  }) {
    return UserFollow(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      followerId: followerId ?? this.followerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
