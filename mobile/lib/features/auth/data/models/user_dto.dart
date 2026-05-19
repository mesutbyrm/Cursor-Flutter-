import '../../domain/entities/user_entity.dart';

class UserDto {
  UserDto({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.followersCount,
    this.followingCount,
    this.isFollowing,
    this.coinBalance,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) return json[k];
      }
      return null;
    }

    final id = pick(['id', 'userId', '_id'])?.toString() ?? '';
    var username = pick(['username', 'userName', 'handle'])?.toString() ?? '';
    if (username.isEmpty) {
      final email = pick(['email'])?.toString();
      if (email != null && email.contains('@')) {
        username = email.split('@').first;
      }
    }

    var followers = _asInt(pick(['followersCount', 'followers', 'followerCount']));
    var following = _asInt(pick(['followingCount', 'following']));
    final countRaw = json['_count'];
    if (countRaw is Map) {
      final cm = Map<String, dynamic>.from(countRaw);
      if (cm.containsKey('followers')) {
        followers = _asInt(cm['followers']);
      }
      if (cm.containsKey('following')) {
        following = _asInt(cm['following']);
      }
    }

    return UserDto(
      id: id,
      username: username.isEmpty ? 'user_$id' : username,
      displayName: pick(['displayName', 'display_name', 'name']) as String?,
      avatarUrl: pick([
            'avatarUrl',
            'avatar_url',
            'photoUrl',
            'avatar',
            'image',
          ])
              as String?,
      bio: pick(['bio', 'about', 'aboutMe', 'description']) as String?,
      followersCount: followers,
      followingCount: following,
      isFollowing: pick(['isFollowing', 'following_me']) == true,
      coinBalance: _asInt(pick(['coinBalance', 'coins', 'balance', 'credits'])),
    );
  }

  /// `/api/user/profile` gibi iç içe `user` / `profile` nesnelerini düzleştirir.
  factory UserDto.fromSiteProfileMap(Map<String, dynamic> root) {
    dynamic pickRoot(List<String> keys) {
      for (final k in keys) {
        if (root.containsKey(k) && root[k] != null) return root[k];
      }
      return null;
    }

    final nested = pickRoot(['user', 'profile', 'data']);
    final merged = Map<String, dynamic>.from(root);
    if (nested is Map) {
      merged.addAll(Map<String, dynamic>.from(nested));
    }
    if (merged['displayName'] == null && merged['name'] != null) {
      merged['displayName'] = merged['name'];
    }
    return UserDto.fromJson(merged);
  }

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final int? followersCount;
  final int? followingCount;
  final bool? isFollowing;
  final int? coinBalance;

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      followersCount: followersCount ?? 0,
      followingCount: followingCount ?? 0,
      isFollowing: isFollowing ?? false,
      coinBalance: coinBalance ?? 0,
    );
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }
}
