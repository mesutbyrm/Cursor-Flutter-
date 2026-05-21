import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/util/json_util.dart';
import '../../domain/entities/user_entity.dart';

part 'user_dto.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class UserDto with _$UserDto {
  const factory UserDto({
    required String id,
    required String username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(false) bool isFollowing,
    @Default(0) int coinBalance,
  }) = _UserDto;

  const UserDto._();

  factory UserDto.fromApiMap(Map<String, dynamic> json) {
    final id = pick(json, ['id', 'userId', '_id'])?.toString() ?? '';
    var username =
        pick(json, ['username', 'userName', 'handle'])?.toString() ?? '';
    if (username.isEmpty) {
      final email = pick(json, ['email'])?.toString();
      if (email != null && email.contains('@')) {
        username = email.split('@').first;
      }
    }

    var followers =
        asInt(pick(json, ['followersCount', 'followers', 'followerCount']));
    var following = asInt(pick(json, ['followingCount', 'following']));
    final countRaw = json['_count'];
    if (countRaw is Map) {
      final cm = Map<String, dynamic>.from(countRaw);
      if (cm.containsKey('followers')) followers = asInt(cm['followers']);
      if (cm.containsKey('following')) following = asInt(cm['following']);
    }

    return UserDto(
      id: id,
      username: username.isEmpty ? 'user_$id' : username,
      displayName:
          pick(json, ['displayName', 'display_name', 'name']) as String?,
      avatarUrl: pick(json, [
        'avatarUrl',
        'avatar_url',
        'photoUrl',
        'avatar',
        'image',
      ]) as String?,
      bio: pick(json, ['bio', 'about', 'aboutMe', 'description']) as String?,
      followersCount: followers,
      followingCount: following,
      isFollowing: pick(json, ['isFollowing', 'following_me']) == true,
      coinBalance:
          asInt(pick(json, ['coinBalance', 'coins', 'balance', 'credits'])),
    );
  }

  /// Geriye dönük uyumluluk.
  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto.fromApiMap(json);

  /// `/api/user/profile` gibi iç içe `user` / `profile` nesnelerini düzleştirir.
  factory UserDto.fromSiteProfileMap(Map<String, dynamic> root) {
    final nested = pick(root, ['user', 'profile', 'data']);
    final merged = Map<String, dynamic>.from(root);
    if (nested is Map) {
      merged.addAll(asJsonMap(nested));
    }
    if (merged['displayName'] == null && merged['name'] != null) {
      merged['displayName'] = merged['name'];
    }
    return UserDto.fromApiMap(merged);
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        followersCount: followersCount,
        followingCount: followingCount,
        isFollowing: isFollowing,
        coinBalance: coinBalance,
      );
}
