import '../../../../core/location/distance_band.dart';
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
    final hidden = pick(json, ['distanceHidden', 'hideDistance']) == true ||
        pick(user, ['distanceHidden', 'hideDistance']) == true;
    final bandKey = pick(json, ['distanceBand', 'distance_band'])?.toString() ??
        pick(user, ['distanceBand', 'distance_band'])?.toString();
    final distKm = pick(json, ['distanceKm', 'distance_km']) ??
        pick(user, ['distanceKm', 'distance_km']);
    final distLegacy = pick(json, ['distance', 'distanceLabel', 'distanceText'])
        ?? pick(user, ['distance', 'distanceLabel', 'distanceText']);
    String? distanceLabel = DistanceBand.labelFromBandKey(bandKey, hidden: hidden);
    if (distanceLabel == null && distKm is num) {
      distanceLabel = DistanceBand.displayLabel(distKm, hidden: hidden);
    } else if (distanceLabel == null && distLegacy is num) {
      distanceLabel = DistanceBand.displayLabel(distLegacy, hidden: hidden);
    } else if (distanceLabel == null && distLegacy is String && distLegacy.isNotEmpty) {
      distanceLabel = hidden ? 'Mesafe bilgisi gizli' : distLegacy;
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
