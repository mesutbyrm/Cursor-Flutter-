import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Sistem sağlığı istatistikleri.
final adminSystemHealthProvider =
    FutureProvider.autoDispose<AdminSystemHealth>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/system-health',
    );
    if (res.data is Map) {
      final data = res.data as Map<String, dynamic>;
      return AdminSystemHealth.fromJson(data);
    }
    return const AdminSystemHealth();
  } catch (e) {
    return const AdminSystemHealth();
  }
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

  const AdminSystemHealth({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.totalTransactions = 0,
    this.apiResponseTime = 0.0,
    this.databaseLoadPercentage = 0.0,
    this.pendingOperations = 0,
    this.errorRate = 0.0,
    this.lastUpdated = '',
  });

  factory AdminSystemHealth.fromJson(Map<String, dynamic> json) {
    return AdminSystemHealth(
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      totalTransactions: json['total_transactions'] as int? ?? 0,
      apiResponseTime: (json['api_response_time'] as num?)?.toDouble() ?? 0.0,
      databaseLoadPercentage:
          (json['database_load_percentage'] as num?)?.toDouble() ?? 0.0,
      pendingOperations: json['pending_operations'] as int? ?? 0,
      errorRate: (json['error_rate'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['last_updated'] as String? ?? '',
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
  excellent,  // Mükemmel
  good,       // İyi
  fair,       // Orta
  poor,       // Zayıf
  critical,   // Kritik
}

HealthStatus calculateHealthStatus(AdminSystemHealth health) {
  // Basit hesaplama: API yanıt süresi, DB yükü, hata oranı
  final apiScore = health.apiResponseTime < 100 ? 1.0 : health.apiResponseTime < 300 ? 0.75 : 0.5;
  final dbScore = health.databaseLoadPercentage < 50 ? 1.0 : health.databaseLoadPercentage < 80 ? 0.75 : 0.5;
  final errorScore = health.errorRate < 1 ? 1.0 : health.errorRate < 5 ? 0.75 : 0.5;

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
