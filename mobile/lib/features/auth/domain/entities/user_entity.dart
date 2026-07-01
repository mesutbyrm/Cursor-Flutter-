import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.role,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.isVerified = false,
    this.coinBalance = 0,
  });

  final String id;
  final String username;
  final String? email;
  final String? role;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool isVerified;
  final int coinBalance;

  String get display => displayName?.trim().isNotEmpty == true
      ? displayName!.trim()
      : username;

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        displayName,
        avatarUrl,
        bio,
        role,
        followersCount,
        followingCount,
        isFollowing,
        isVerified,
        coinBalance,
      ];
}
