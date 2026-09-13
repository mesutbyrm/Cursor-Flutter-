import '../../../../core/util/json_util.dart';

/// `GET /api/social/discovery` — OpenAPI şema MISSING; yalnızca wire alanları okunur.
class SocialDiscoveryUser {
  const SocialDiscoveryUser({
    required this.id,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.distanceLabel,
    this.raw = const {},
  });

  final String id;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String? distanceLabel;
  final Map<String, dynamic> raw;

  factory SocialDiscoveryUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? asJsonMap(json['user'])
        : json['target'] is Map
            ? asJsonMap(json['target'])
            : json;
    final id = pick(user, ['id', 'userId', 'targetId'])?.toString() ?? '';
    final name = pick(user, [
      'displayName',
      'name',
      'username',
      'nickname',
    ])?.toString();
    final username = user['username']?.toString();
    final avatar = pick(user, [
      'avatar',
      'avatarUrl',
      'image',
      'profileImage',
      'photo',
    ])?.toString();
    final dist = pick(json, ['distance', 'distanceKm', 'distanceLabel', 'distanceText'])
        ?? pick(user, ['distance', 'distanceKm', 'distanceLabel', 'distanceText']);
    String? distanceLabel;
    if (dist is num) {
      distanceLabel = '${dist.toStringAsFixed(dist is int ? 0 : 1)} km';
    } else if (dist != null) {
      distanceLabel = dist.toString();
    }
    return SocialDiscoveryUser(
      id: id,
      displayName: (name != null && name.isNotEmpty) ? name : (username ?? 'Kullanıcı'),
      username: username,
      avatarUrl: avatar,
      distanceLabel: distanceLabel,
      raw: Map<String, dynamic>.from(json),
    );
  }
}
