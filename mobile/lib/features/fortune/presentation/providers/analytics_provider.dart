import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_instance.dart';

// Models
class UserMetrics {
  final String userId;
  final int totalReadings;
  final int totalVoiceReadings;
  final int totalMatches;
  final int totalShares;
  final int averageReadingTime;
  final int longestStreak;
  final int currentStreak;
  final String? preferredCategory;
  final String? mostUsedReadingType;
  final double engagementScore;
  final double retentionScore;
  final DateTime? lastReadingAt;
  final DateTime? lastActiveAt;

  UserMetrics({
    required this.userId,
    required this.totalReadings,
    required this.totalVoiceReadings,
    required this.totalMatches,
    required this.totalShares,
    required this.averageReadingTime,
    required this.longestStreak,
    required this.currentStreak,
    this.preferredCategory,
    this.mostUsedReadingType,
    required this.engagementScore,
    required this.retentionScore,
    this.lastReadingAt,
    this.lastActiveAt,
  });

  factory UserMetrics.fromJson(Map<String, dynamic> json) {
    return UserMetrics(
      userId: json['userId'] as String,
      totalReadings: json['totalReadings'] as int,
      totalVoiceReadings: json['totalVoiceReadings'] as int,
      totalMatches: json['totalMatches'] as int,
      totalShares: json['totalShares'] as int,
      averageReadingTime: json['averageReadingTime'] as int,
      longestStreak: json['longestStreak'] as int,
      currentStreak: json['currentStreak'] as int,
      preferredCategory: json['preferredCategory'] as String?,
      mostUsedReadingType: json['mostUsedReadingType'] as String?,
      engagementScore: (json['engagementScore'] as num).toDouble(),
      retentionScore: (json['retentionScore'] as num).toDouble(),
      lastReadingAt: json['lastReadingAt'] != null
          ? DateTime.parse(json['lastReadingAt'] as String)
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
    );
  }
}

class AnalyticsSnapshot {
  final String id;
  final String userId;
  final String period;
  final DateTime date;
  final int readingCount;
  final int voiceReadingCount;
  final int matchCount;
  final int shareCount;
  final int screenViews;
  final int sessionDuration;

  AnalyticsSnapshot({
    required this.id,
    required this.userId,
    required this.period,
    required this.date,
    required this.readingCount,
    required this.voiceReadingCount,
    required this.matchCount,
    required this.shareCount,
    required this.screenViews,
    required this.sessionDuration,
  });

  factory AnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    return AnalyticsSnapshot(
      id: json['id'] as String,
      userId: json['userId'] as String,
      period: json['period'] as String,
      date: DateTime.parse(json['date'] as String),
      readingCount: json['readingCount'] as int,
      voiceReadingCount: json['voiceReadingCount'] as int,
      matchCount: json['matchCount'] as int,
      shareCount: json['shareCount'] as int,
      screenViews: json['screenViews'] as int? ?? 0,
      sessionDuration: json['sessionDuration'] as int? ?? 0,
    );
  }
}

// Service
class AnalyticsService {
  final Dio _dio;

  AnalyticsService(this._dio);

  Future<UserMetrics> getMetrics() async {
    final response = await _dio.get('/api/analytics/metrics');
    return UserMetrics.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AnalyticsSnapshot> getDailySnapshot(DateTime date) async {
    final response = await _dio.get(
      '/api/analytics/snapshot',
      queryParameters: {'date': date.toIso8601String()},
    );
    return AnalyticsSnapshot.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getEngagementTrend({int days = 30}) async {
    final response = await _dio.get(
      '/api/analytics/trend',
      queryParameters: {'days': days},
    );
    return List<Map<String, dynamic>>.from(response.data['data']['trend'] as List);
  }

  Future<List<AnalyticsSnapshot>> getAnalyticsPeriod({
    required DateTime startDate,
    required DateTime endDate,
    String period = 'daily',
  }) async {
    final response = await _dio.get(
      '/api/analytics/period',
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'period': period,
      },
    );
    return (response.data['data']['snapshots'] as List)
        .map((s) => AnalyticsSnapshot.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> generateReport() async {
    final response = await _dio.get('/api/analytics/report');
    return response.data['data'] as Map<String, dynamic>;
  }
}

// Providers
final analyticsServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AnalyticsService(dio);
});

final userMetricsProvider = FutureProvider<UserMetrics>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getMetrics();
});

final dailySnapshotProvider = FutureProvider.family<AnalyticsSnapshot, DateTime>(
  (ref, date) async {
    final service = ref.watch(analyticsServiceProvider);
    return service.getDailySnapshot(date);
  },
);

final engagementTrendProvider = FutureProvider.family<List<Map<String, dynamic>>, int>(
  (ref, days) async {
    final service = ref.watch(analyticsServiceProvider);
    return service.getEngagementTrend(days: days);
  },
);

final analyticsPeriodProvider = FutureProvider.family<
  List<AnalyticsSnapshot>,
  ({DateTime startDate, DateTime endDate, String period})
>(
  (ref, params) async {
    final service = ref.watch(analyticsServiceProvider);
    return service.getAnalyticsPeriod(
      startDate: params.startDate,
      endDate: params.endDate,
      period: params.period,
    );
  },
);

final analyticsReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.generateReport();
});
