import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/util/json_util.dart';
import '../../../../core/auth/bot_account_guard.dart';
import '../../domain/entities/user_entity.dart';

part 'user_dto.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class UserDto with _$UserDto {
  const factory UserDto({
    required String id,
    required String username,
    String? email,
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
    final id = pick(json, ['id', 'userId', '_id', 'sub'])?.toString() ?? '';
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
      email: pick(json, ['email'])?.toString(),
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
      coinBalance: asInt(pick(json, [
        'jetonBalance',
        'coinBalance',
        'coins',
        'balance',
        'credits',
      ])),
    );
  }

  String? roleFrom(Map<String, dynamic> json) {
    final direct = pick(json, ['role', 'tier', 'userRole'])?.toString();
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();

    final membership = pick(json, [
      'membership',
      'membershipTier',
      'membership_tier',
      'vipLevel',
      'vip_level',
      'subscription',
      'subscriptionTier',
      'subscription_tier',
      'plan',
      'userMembership',
    ])?.toString();
    if (membership != null && membership.trim().isNotEmpty) {
      final normalized = membership.trim().toLowerCase();
      if (normalized != 'free' &&
          normalized != 'basic' &&
          normalized != 'member' &&
          normalized != 'üye') {
        return membership.trim();
      }
    }

    if (json['isFortuneTeller'] == true ||
        json['isLiveFortuneTeller'] == true ||
        json['canGoOnline'] == true) {
      return 'fortune_teller';
    }
    if (json['isAgency'] == true ||
        json['isAgencyOwner'] == true ||
        json['isAgencyAdmin'] == true) {
      return 'agency';
    }

    final roles = json['roles'];
    if (roles is List) {
      for (final r in roles) {
        final s = r.toString().toLowerCase();
        if (s.contains('teller') ||
            s.contains('fortune') ||
            s.contains('falc') ||
            s.contains('falci')) {
          return 'fortune_teller';
        }
        if (s.contains('agency') || s.contains('ajans')) return 'agency';
      }
    }

    if (pick(json, ['fortuneTellerId', 'liveFortuneTellerId', 'tellerId']) !=
        null) {
      return 'fortune_teller';
    }
    if (pick(json, ['agencyId', 'agency_id', 'liveAgencyId']) != null) {
      return 'agency';
    }

    return null;
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
    final role = pick(root, ['role']) ?? pick(merged, ['role', 'tier']);
    if (role != null) {
      merged['role'] = role;
    }
    return UserDto.fromApiMap(merged);
  }

  UserEntity toEntity({String? role, Map<String, dynamic>? source}) => UserEntity(
        id: id,
        username: username,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        role: role,
        followersCount: followersCount,
        followingCount: followingCount,
        isFollowing: isFollowing,
        coinBalance: coinBalance,
        isBot: BotAccountGuard.fromJsonMap(source),
      );
}
