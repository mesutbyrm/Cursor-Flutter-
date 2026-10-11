import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

/// Sistem sağlığı — önce PR #40 `GET /api/admin/health`, yoksa legacy uç.
final adminSystemHealthProvider =
    FutureProvider.autoDispose<AdminSystemHealth>((ref) async {
  final dio = ref.watch(dioProvider);
  for (final path in [
    ApiEndpoints.adminHealth,
    '${ApiEndpoints.adminUsers}/system-health',
  ]) {
    try {
      final res = await dio.safeGet<dynamic>(path, forceRefresh: true);
      if (res.data is Map) {
        return AdminSystemHealth.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
      }
    } catch (_) {
      continue;
    }
  }
  return const AdminSystemHealth();
});

/// Sistem sağlığı bilgileri.
class AdminSystemHealth {
  final int totalUsers;
  final int activeUsers;
  final int totalTransactions;
  final double apiResponseTime; // ms
  final double databaseLoadPercentage;
  final int pendingOperations;
  final double errorRate; // %
  final String lastUpdated;
  final String serverStatus;

  const AdminSystemHealth({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.totalTransactions = 0,
    this.apiResponseTime = 0.0,
    this.databaseLoadPercentage = 0.0,
    this.pendingOperations = 0,
    this.errorRate = 0.0,
    this.lastUpdated = '',
    this.serverStatus = '',
  });

  factory AdminSystemHealth.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map ? asJsonMap(json['data']) : asJsonMap(json);

    // Legacy snake_case flat map
    if (root.containsKey('total_users') || root.containsKey('api_response_time')) {
      return AdminSystemHealth(
        totalUsers: root['total_users'] as int? ?? 0,
        activeUsers: root['active_users'] as int? ?? 0,
        totalTransactions: root['total_transactions'] as int? ?? 0,
        apiResponseTime: (root['api_response_time'] as num?)?.toDouble() ?? 0.0,
        databaseLoadPercentage:
            (root['database_load_percentage'] as num?)?.toDouble() ?? 0.0,
        pendingOperations: root['pending_operations'] as int? ?? 0,
        errorRate: (root['error_rate'] as num?)?.toDouble() ?? 0.0,
        lastUpdated: root['last_updated']?.toString() ?? '',
        serverStatus: root['status']?.toString() ?? '',
      );
    }

    final db = root['database'] is Map ? asJsonMap(root['database']) : {};
    final users = root['users'] is Map ? asJsonMap(root['users']) : {};
    final payments = root['payments'] is Map ? asJsonMap(root['payments']) : {};
    final moderation =
        root['moderation'] is Map ? asJsonMap(root['moderation']) : {};
    final latency = (db['latencyMs'] as num?)?.toDouble() ?? 0.0;
    final pending = (payments['pending'] as num?)?.toInt() ?? 0;
    final modPending = (moderation['pendingReports'] as num?)?.toInt() ?? 0;

    return AdminSystemHealth(
      totalUsers: (users['total'] as num?)?.toInt() ?? 0,
      activeUsers: (users['activeLastHour'] as num?)?.toInt() ?? 0,
      totalTransactions: (payments['total'] as num?)?.toInt() ?? 0,
      apiResponseTime: latency,
      databaseLoadPercentage: db['connected'] == false ? 100 : latency / 5,
      pendingOperations: pending + modPending,
      errorRate: (payments['failedToday'] as num?)?.toDouble() ?? 0,
      lastUpdated: root['timestamp']?.toString() ?? '',
      serverStatus: root['status']?.toString() ?? '',
    );
  }
}

/// Günlük aktivite istatistikleri.
final adminDailyStatsProvider =
    FutureProvider.autoDispose<List<DailyStat>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/daily-stats',
      query: {'days': '7'},
    );
    if (res.data is List) {
      return (res.data as List)
          .map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Günlük istatistik.
class DailyStat {
  final String date;
  final int newUsers;
  final int activeUsers;
  final double revenue;
  final int transactions;

  DailyStat({
    required this.date,
    required this.newUsers,
    required this.activeUsers,
    required this.revenue,
    required this.transactions,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    return DailyStat(
      date: json['date'] as String? ?? '',
      newUsers: json['new_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      transactions: json['transactions'] as int? ?? 0,
    );
  }
}

/// Sistem sağlığı durumu.
enum HealthStatus {
  excellent,
  good,
  fair,
  poor,
  critical,
}

HealthStatus calculateHealthStatus(AdminSystemHealth health) {
  if (health.serverStatus == 'healthy') return HealthStatus.excellent;
  if (health.serverStatus == 'degraded') return HealthStatus.fair;

  final apiScore =
      health.apiResponseTime < 100 ? 1.0 : health.apiResponseTime < 300 ? 0.75 : 0.5;
  final dbScore = health.databaseLoadPercentage < 50
      ? 1.0
      : health.databaseLoadPercentage < 80
          ? 0.75
          : 0.5;
  final errorScore =
      health.errorRate < 1 ? 1.0 : health.errorRate < 5 ? 0.75 : 0.5;

  final avgScore = (apiScore + dbScore + errorScore) / 3;

  if (avgScore >= 0.9) return HealthStatus.excellent;
  if (avgScore >= 0.75) return HealthStatus.good;
  if (avgScore >= 0.6) return HealthStatus.fair;
  if (avgScore >= 0.4) return HealthStatus.poor;
  return HealthStatus.critical;
}

String healthStatusLabel(HealthStatus status) {
  switch (status) {
    case HealthStatus.excellent:
      return 'Mükemmel';
    case HealthStatus.good:
      return 'İyi';
    case HealthStatus.fair:
      return 'Orta';
    case HealthStatus.poor:
      return 'Zayıf';
    case HealthStatus.critical:
      return 'Kritik';
  }
}
