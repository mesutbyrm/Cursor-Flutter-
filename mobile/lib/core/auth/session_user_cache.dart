import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../network/token_storage.dart';

const _kCachedUser = 'cached_session_user_v1';

final sessionUserCacheProvider = Provider<SessionUserCache>((ref) {
  return SessionUserCache(ref.watch(secureStorageProvider));
});

/// Son bilinen oturum — ağ yavaşken veya kısa boot timeout'ta yeniden giriş istemez.
class SessionUserCache {
  SessionUserCache(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> write(UserEntity user) async {
    if (user.id.isEmpty) return;
    final map = {
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'displayName': user.displayName,
      'avatarUrl': user.avatarUrl,
      'bio': user.bio,
      'role': user.role,
      'followersCount': user.followersCount,
      'followingCount': user.followingCount,
      'isFollowing': user.isFollowing,
      'coinBalance': user.coinBalance,
    };
    await _storage.write(key: _kCachedUser, value: jsonEncode(map));
  }

  Future<UserEntity?> read() async {
    final raw = await _storage.read(key: _kCachedUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final id = map['id']?.toString() ?? '';
      if (id.isEmpty) return null;
      return UserEntity(
        id: id,
        username: map['username']?.toString() ?? id,
        email: map['email']?.toString(),
        displayName: map['displayName']?.toString(),
        avatarUrl: map['avatarUrl']?.toString(),
        bio: map['bio']?.toString(),
        role: map['role']?.toString(),
        followersCount: (map['followersCount'] as num?)?.toInt() ?? 0,
        followingCount: (map['followingCount'] as num?)?.toInt() ?? 0,
        isFollowing: map['isFollowing'] == true,
        coinBalance: (map['coinBalance'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _kCachedUser);
}
