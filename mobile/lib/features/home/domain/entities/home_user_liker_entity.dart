import '../../../../core/util/json_util.dart';

/// `GET /api/user/likers` beğeni satırı.
class HomeUserLikerEntity {
  const HomeUserLikerEntity({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.timeLabel,
  });

  factory HomeUserLikerEntity.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? asJsonMap(json['user']) : json;
    final name = pick(user, ['displayName', 'name', 'username'])?.toString() ??
        pick(json, ['displayName', 'name', 'username'])?.toString() ??
        '';
    return HomeUserLikerEntity(
      id: pick(user, ['id', 'userId', '_id'])?.toString() ??
          pick(json, ['id', 'userId', '_id'])?.toString() ??
          name.hashCode.toString(),
      displayName: name,
      avatarUrl: pick(user, ['avatarUrl', 'avatar', 'image'])?.toString() ??
          pick(json, ['avatarUrl', 'avatar', 'image'])?.toString(),
      timeLabel: pick(json, ['timeLabel', 'time', 'likedAt', 'createdAt'])
          ?.toString(),
    );
  }

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? timeLabel;

  bool get isValid => displayName.trim().isNotEmpty;
}
