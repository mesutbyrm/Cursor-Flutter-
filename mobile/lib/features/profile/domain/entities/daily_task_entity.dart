import '../../../../core/util/json_util.dart';

class DailyTaskEntity {
  const DailyTaskEntity({
    required this.id,
    required this.title,
    this.description,
    this.current = 0,
    this.target = 1,
    this.completed = false,
    this.claimed = false,
    this.rewardJeton = 0,
    this.rewardXp = 0,
    this.route,
    this.icon,
  });

  factory DailyTaskEntity.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'];
    int current = asInt(pick(json, ['current', 'progress', 'count']));
    int target = asInt(pick(json, ['target', 'goal', 'required', 'max']));
    if (progress is Map) {
      final pm = Map<String, dynamic>.from(progress);
      final pCurrent = pick(pm, ['current', 'value', 'count']);
      final pTarget = pick(pm, ['target', 'goal', 'max']);
      if (pCurrent != null) current = asInt(pCurrent);
      if (pTarget != null) target = asInt(pTarget);
    }
    return DailyTaskEntity(
      id: pick(json, ['id', 'taskId', 'slug', 'key'])?.toString() ?? '',
      title: pick(json, ['title', 'name', 'label'])?.toString() ?? 'Görev',
      description: pick(json, ['description', 'detail'])?.toString(),
      current: current,
      target: target < 1 ? 1 : target,
      completed: json['completed'] == true ||
          json['done'] == true ||
          json['isCompleted'] == true ||
          (target > 0 && current >= target),
      claimed: json['claimed'] == true || json['rewardClaimed'] == true,
      rewardJeton: asInt(pick(json, ['rewardJeton', 'jetonReward', 'coins'])),
      rewardXp: asInt(pick(json, ['rewardXp', 'xpReward', 'xp'])),
      route: pick(json, ['route', 'deepLink', 'path'])?.toString(),
      icon: pick(json, ['icon', 'emoji'])?.toString(),
    );
  }

  final String id;
  final String title;
  final String? description;
  final int current;
  final int target;
  final bool completed;
  final bool claimed;
  final int rewardJeton;
  final int rewardXp;
  final String? route;
  final String? icon;

  double get progressRatio => (current / target).clamp(0.0, 1.0);
}

int _intOr(dynamic v, int fallback) {
  if (v == null) return fallback;
  final n = asInt(v);
  return n > 0 ? n : fallback;
}

class UserLevelEntity {
  const UserLevelEntity({
    this.level = 1,
    this.xp = 0,
    this.xpToNext = 100,
    this.vipTier,
    this.isVip = false,
  });

  factory UserLevelEntity.fromJson(Map<String, dynamic> json) {
    final m = json['user'] is Map
        ? asJsonMap(json['user'])
        : json['data'] is Map
            ? asJsonMap(json['data'])
            : json;
    return UserLevelEntity(
      level: _intOr(pick(m, ['level', 'userLevel']), 1),
      xp: asInt(pick(m, ['xp', 'experience', 'experiencePoints'])),
      xpToNext: _intOr(
        pick(m, ['xpToNext', 'nextLevelXp', 'xpForNextLevel']),
        100,
      ),
      vipTier: pick(m, ['vipTier', 'membership', 'membershipTier'])?.toString(),
      isVip: m['isVip'] == true ||
          m['vip'] == true ||
          (pick(m, ['membership'])?.toString().trim().isNotEmpty == true),
    );
  }

  final int level;
  final int xp;
  final int xpToNext;
  final String? vipTier;
  final bool isVip;
}
