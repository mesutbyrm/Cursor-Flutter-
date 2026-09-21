import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_provider.dart';

// Models
class UserStreak {
  final int currentStreak;
  final int bestStreak;
  final DateTime? bestStreakStart;
  final DateTime? bestStreakEnd;
  final int totalReadingsInStreak;
  final DateTime? lastReadingDate;
  final DateTime? streakBrokenDate;
  final List<StreakMilestone> milestones;

  UserStreak({
    required this.currentStreak,
    required this.bestStreak,
    this.bestStreakStart,
    this.bestStreakEnd,
    required this.totalReadingsInStreak,
    this.lastReadingDate,
    this.streakBrokenDate,
    required this.milestones,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      currentStreak: json['currentStreak'] as int,
      bestStreak: json['bestStreak'] as int,
      bestStreakStart: json['bestStreakStart'] != null
          ? DateTime.parse(json['bestStreakStart'] as String)
          : null,
      bestStreakEnd: json['bestStreakEnd'] != null
          ? DateTime.parse(json['bestStreakEnd'] as String)
          : null,
      totalReadingsInStreak: json['totalReadingsInStreak'] as int,
      lastReadingDate: json['lastReadingDate'] != null
          ? DateTime.parse(json['lastReadingDate'] as String)
          : null,
      streakBrokenDate: json['streakBrokenDate'] != null
          ? DateTime.parse(json['streakBrokenDate'] as String)
          : null,
      milestones: (json['milestones'] as List)
          .map((m) => StreakMilestone.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StreakMilestone {
  final int streakDays;
  final DateTime? achievedAt;
  final bool locked;

  StreakMilestone({
    required this.streakDays,
    this.achievedAt,
    required this.locked,
  });

  factory StreakMilestone.fromJson(Map<String, dynamic> json) {
    return StreakMilestone(
      streakDays: json['streakDays'] as int,
      achievedAt: json['achievedAt'] != null
          ? DateTime.parse(json['achievedAt'] as String)
          : null,
      locked: json['locked'] as bool,
    );
  }
}

class Achievement {
  final String achievementId;
  final String title;
  final String description;
  final String icon;
  final String rarity;
  final int points;
  final bool unlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int maxProgress;

  Achievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.points,
    required this.unlocked,
    this.unlockedAt,
    required this.progress,
    required this.maxProgress,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      achievementId: json['achievementId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      rarity: json['rarity'] as String,
      points: json['points'] as int,
      unlocked: json['unlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progress: json['progress'] as int,
      maxProgress: json['maxProgress'] as int,
    );
  }
}

class UserLevel {
  final int level;
  final String levelName;
  final int currentXP;
  final int xpNeeded;
  final double levelProgress;
  final int totalXP;
  final int nextLevelAt;

  UserLevel({
    required this.level,
    required this.levelName,
    required this.currentXP,
    required this.xpNeeded,
    required this.levelProgress,
    required this.totalXP,
    required this.nextLevelAt,
  });

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      level: json['level'] as int,
      levelName: json['levelName'] as String,
      currentXP: json['currentXP'] as int,
      xpNeeded: json['xpNeeded'] as int,
      levelProgress: (json['levelProgress'] as num).toDouble(),
      totalXP: json['totalXP'] as int,
      nextLevelAt: json['nextLevelAt'] as int,
    );
  }
}

// Service
class AchievementsService {
  final Dio _dio;

  AchievementsService(this._dio);

  Future<UserStreak> getStreaks() async {
    final response = await _dio.get('/api/achievements/streaks');
    return UserStreak.fromJson(response.data['data']);
  }

  Future<List<Achievement>> getAchievements({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get('/api/achievements', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return (response.data['data']['achievements'] as List)
        .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<UserLevel> getLevel() async {
    final response = await _dio.get('/api/achievements/level');
    return UserLevel.fromJson(response.data['data']);
  }

  Future<void> syncStreaks() async {
    await _dio.post('/api/achievements/sync-streaks', data: {
      'lastSyncDate': DateTime.now().toIso8601String(),
    });
  }
}

// Providers
final achievementsServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AchievementsService(dio);
});

final userStreakProvider = FutureProvider<UserStreak>((ref) async {
  final service = ref.watch(achievementsServiceProvider);
  return service.getStreaks();
});

final achievementsProvider = FutureProvider.family<List<Achievement>, ({int limit, int offset})>(
  (ref, params) async {
    final service = ref.watch(achievementsServiceProvider);
    return service.getAchievements(
      limit: params.limit,
      offset: params.offset,
    );
  },
);

final userLevelProvider = FutureProvider<UserLevel>((ref) async {
  final service = ref.watch(achievementsServiceProvider);
  return service.getLevel();
});

// Sync notifier
class SyncStreaksNotifier extends StateNotifier<AsyncValue<void>> {
  final AchievementsService _service;

  SyncStreaksNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> syncStreaks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.syncStreaks());
  }
}

final syncStreaksProvider = StateNotifierProvider<SyncStreaksNotifier, AsyncValue<void>>(
  (ref) => SyncStreaksNotifier(ref.watch(achievementsServiceProvider)),
);
