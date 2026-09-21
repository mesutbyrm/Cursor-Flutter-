import 'package:flutter_riverpod/flutter_riverpod.dart';

class PerformanceMetrics {
  final String userId;
  final int? appOpenTime;
  final int? pageLoadTime;
  final int? apiResponseTime;
  final int? batteryUsage;
  final int? dataUsage;
  final int? memoryUsage;
  final int? crashCount;

  PerformanceMetrics({
    required this.userId,
    this.appOpenTime,
    this.pageLoadTime,
    this.apiResponseTime,
    this.batteryUsage,
    this.dataUsage,
    this.memoryUsage,
    this.crashCount,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      userId: json['userId'] ?? '',
      appOpenTime: json['appOpenTime'],
      pageLoadTime: json['pageLoadTime'],
      apiResponseTime: json['apiResponseTime'],
      batteryUsage: json['batteryUsage'],
      dataUsage: json['dataUsage'],
      memoryUsage: json['memoryUsage'],
      crashCount: json['crashCount'],
    );
  }
}

class PerformanceMonitoringService {
  Future<void> recordMetrics(String userId, {
    int? appOpenTime,
    int? pageLoadTime,
    int? apiResponseTime,
    int? batteryUsage,
    int? dataUsage,
    int? memoryUsage,
    int? crashCount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<PerformanceMetrics> getMetrics(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return PerformanceMetrics(userId: userId);
  }

  Future<Map<String, dynamic>> getPerformanceReport(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'analysis': {},
      'recommendations': [],
    };
  }
}

final performanceMonitoringServiceProvider = Provider((ref) => PerformanceMonitoringService());

final performanceMetricsProvider = FutureProvider.family<PerformanceMetrics, String>((ref, userId) async {
  final service = ref.watch(performanceMonitoringServiceProvider);
  return service.getMetrics(userId);
});

final performanceReportProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final service = ref.watch(performanceMonitoringServiceProvider);
  return service.getPerformanceReport(userId);
});

class RecordMetricsNotifier extends StateNotifier<AsyncValue<void>> {
  RecordMetricsNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> record(String userId, {
    int? appOpenTime,
    int? pageLoadTime,
    int? apiResponseTime,
    int? batteryUsage,
    int? dataUsage,
    int? memoryUsage,
    int? crashCount,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(performanceMonitoringServiceProvider);
      await service.recordMetrics(
        userId,
        appOpenTime: appOpenTime,
        pageLoadTime: pageLoadTime,
        apiResponseTime: apiResponseTime,
        batteryUsage: batteryUsage,
        dataUsage: dataUsage,
        memoryUsage: memoryUsage,
        crashCount: crashCount,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final recordMetricsNotifierProvider = StateNotifierProvider<RecordMetricsNotifier, AsyncValue<void>>((ref) {
  return RecordMetricsNotifier(ref);
});
