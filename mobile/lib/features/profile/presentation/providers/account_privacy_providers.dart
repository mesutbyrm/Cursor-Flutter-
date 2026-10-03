import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

/// Engellenen kullanıcı satırı — `GET /api/user/block`.
class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.name,
    this.username,
    this.image,
  });

  final String userId;
  final String name;
  final String? username;
  final String? image;

  factory BlockedUser.fromJson(Map<String, dynamic> j) {
    final username = pick(j, ['username'])?.toString();
    final name = pick(j, ['name', 'displayName'])?.toString();
    return BlockedUser(
      userId: pick(j, ['userId', 'id'])?.toString() ?? '',
      name: (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (username ?? 'Kullanıcı'),
      username: username,
      image: pick(j, ['image', 'avatarUrl'])?.toString(),
    );
  }
}

/// `{success, data:[…]}` yanıtını liste olarak okur.
List<BlockedUser> parseBlockedUsers(dynamic body) {
  final map = asJsonMap(body);
  final raw = map['data'] ?? map['blocked'] ?? map['users'];
  return [
    for (final row in asJsonList(raw))
      if ((pick(row, ['userId', 'id'])?.toString() ?? '').isNotEmpty)
        BlockedUser.fromJson(row),
  ];
}

final blockedUsersProvider =
    FutureProvider.autoDispose<List<BlockedUser>>((ref) async {
  final res = await ref.watch(dioProvider).safeGet<dynamic>(
        ApiEndpoints.userBlock,
        forceRefresh: true,
      );
  return parseBlockedUsers(res.data);
});

/// Engeli kaldır — `POST /api/user/block {userId}` aç/kapa uç; sonuç
/// `{blocked}` hâlâ true ise bir kez daha çağrılır.
Future<void> unblockUser(WidgetRef ref, String userId) async {
  final dio = ref.read(dioProvider);
  for (var i = 0; i < 2; i++) {
    final res = await dio.safePost<dynamic>(
      ApiEndpoints.userBlock,
      data: {'userId': userId},
    );
    final now = asJsonMap(res.data)['blocked'];
    if (now is! bool || now == false) break;
  }
  ref.invalidate(blockedUsersProvider);
}

/// Hesabı kalıcı sil (sunucu anonimleştirir). Şifreli hesaplarda [password] şart.
Future<void> deleteMyAccount(WidgetRef ref, {String? password}) async {
  await ref.read(dioProvider).safePost<dynamic>(
    ApiEndpoints.userAccountDelete,
    data: {
      'confirm': true,
      if (password != null && password.isNotEmpty) 'password': password,
    },
  );
}
