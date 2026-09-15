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
    this.actionAt,
    this.raw = const {},
  });

  final String id;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String? distanceLabel;
  /// Eşleşme / aksiyon satırı zamanı (`createdAt` vb.).
  final DateTime? actionAt;
  final Map<String, dynamic> raw;

  int? get age {
    final rawUser = _profileMap;
    final age = pick(rawUser, ['age', 'userAge']);
    return age is num ? age.round() : int.tryParse('$age');
  }

  String? get city => pick(_profileMap, ['city', 'location'])?.toString();

  String? get gender =>
      pick(_profileMap, ['gender', 'sex', 'genderPreference'])?.toString();

  String? get bio =>
      pick(_profileMap, ['bio', 'about', 'description'])?.toString();

  String? get membership =>
      pick(_profileMap, ['membership', 'vipTier', 'tier'])?.toString();

  bool get isVerified => pick(_profileMap, ['isVerified', 'verified']) == true;

  List<String> get hobbies {
    final raw = pick(_profileMap, ['hobbies', 'interests', 'tags']);
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  List<String> get commonHobbies {
    final raw = pick(_profileMap, ['commonHobbies', 'common_hobbies']);
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  static DateTime? _parseActionAt(Map<String, dynamic> json) {
    for (final key in [
      'createdAt',
      'created_at',
      'matchedAt',
      'updatedAt',
      'timestamp',
    ]) {
      final v = pick(json, [key]);
      if (v is String) {
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt;
      }
    }
    return null;
  }

  /// Ham km (varsa) — istemci mesafe filtresi için.
  double? get distanceKm {
    final v = pick(raw, ['distanceKm', 'distance_km']) ??
        pick(_profileMap, ['distanceKm', 'distance_km', 'distance']);
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  int? get matchPercent {
    final v = pick(_profileMap, ['matchPercent', 'match_percent']);
    if (v is num) return v.round().clamp(0, 100);
    return int.tryParse('$v');
  }

  bool get isOnline {
    if (pick(_profileMap, ['isOnline', 'online']) == true) return true;
    final last = pick(_profileMap, ['lastActive', 'lastSeenAt']);
    if (last is String) {
      final dt = DateTime.tryParse(last);
      if (dt != null) {
        return DateTime.now().toUtc().difference(dt.toUtc()).inMinutes < 10;
      }
    }
    return false;
  }

  String? get coverMediaUrl {
    final v = pick(_profileMap, [
      'profileVideo',
      'videoUrl',
      'introVideo',
      'coverVideo',
    ])?.toString();
    if (v != null && v.trim().isNotEmpty) return v.trim();
    return avatarUrl;
  }

  Map<String, dynamic> get _profileMap {
    if (raw['user'] is Map) return asJsonMap(raw['user']);
    if (raw['target'] is Map) return asJsonMap(raw['target']);
    if (raw['otherUser'] is Map) return asJsonMap(raw['otherUser']);
    return raw;
  }

  factory SocialDiscoveryUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? asJsonMap(json['user'])
        : json['target'] is Map
            ? asJsonMap(json['target'])
            : json['otherUser'] is Map
                ? asJsonMap(json['otherUser'])
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
    final city = pick(user, ['city'])?.toString();
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
    final merged = Map<String, dynamic>.from(user);
    if (city != null && city.isNotEmpty) merged['city'] = city;
    return SocialDiscoveryUser(
      id: id,
      displayName: (name != null && name.isNotEmpty) ? name : (username ?? 'Kullanıcı'),
      username: username,
      avatarUrl: avatar,
      distanceLabel: distanceLabel,
      actionAt: _parseActionAt(json),
      raw: json['user'] is Map || json['target'] is Map || json['otherUser'] is Map
          ? Map<String, dynamic>.from(json)
          : merged,
    );
  }

  factory SocialDiscoveryUser.fromActionRow(Map<String, dynamic> row) {
    final other = row['otherUser'] ?? row['target'] ?? row['user'];
    if (other is Map) {
      final user = SocialDiscoveryUser.fromJson({
        ...Map<String, dynamic>.from(row),
        'otherUser': Map<String, dynamic>.from(other),
      });
      return SocialDiscoveryUser(
        id: user.id,
        displayName: user.displayName,
        username: user.username,
        avatarUrl: user.avatarUrl,
        distanceLabel: user.distanceLabel,
        actionAt: _parseActionAt(row) ?? user.actionAt,
        raw: user.raw,
      );
    }
    final targetId = pick(row, ['targetId', 'userId'])?.toString() ?? '';
    return SocialDiscoveryUser(
      id: targetId,
      displayName: pick(row, ['targetName', 'name'])?.toString() ?? 'Kullanıcı',
      actionAt: _parseActionAt(row),
      raw: row,
    );
  }
}
