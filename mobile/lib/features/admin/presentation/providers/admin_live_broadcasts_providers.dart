import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Canlı yayın kontrol - aktif yayınları yönet.
final adminActiveBroadcastsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.liveStreams}/admin/active',
      query: {'limit': '50'},
    );
    if (res.data is List) {
      return List<Map<String, dynamic>>.from(
        (res.data as List).map((e) => e is Map ? e : {}),
      );
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Aktif yayın sayısı.
final adminActiveBroadcastCountProvider = Provider<int>((ref) {
  final broadcasts = ref.watch(adminActiveBroadcastsProvider).valueOrNull ?? [];
  return broadcasts.length;
});

/// Uyarı gerektiren yayınlar (spam, uygunsuz içerik vb).
final adminFlaggedBroadcastsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.liveStreams}/admin/flagged',
      query: {'limit': '50'},
    );
    if (res.data is List) {
      return List<Map<String, dynamic>>.from(
        (res.data as List).map((e) => e is Map ? e : {}),
      );
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Uyarılı yayın sayısı.
final adminFlaggedBroadcastCountProvider = Provider<int>((ref) {
  final broadcasts = ref.watch(adminFlaggedBroadcastsProvider).valueOrNull ?? [];
  return broadcasts.length;
});

/// Yayın moderasyon işlemleri.
enum BroadcastModerationAction {
  warning,      // Uyarı gönder
  suspend,      // Yayını askıya al
  terminate,    // Yayını sonlandır
  ban,          // Yayıncıyı yasakla
  timeout,      // Geçici mute
}

String broadcastModerationActionLabel(BroadcastModerationAction action) {
  switch (action) {
    case BroadcastModerationAction.warning:
      return 'Uyarı Gönder';
    case BroadcastModerationAction.suspend:
      return 'Yayını Askıya Al';
    case BroadcastModerationAction.terminate:
      return 'Yayını Sonlandır';
    case BroadcastModerationAction.ban:
      return 'Yayıncıyı Yasakla';
    case BroadcastModerationAction.timeout:
      return 'Geçici Mute';
  }
}

/// Yayın düşük/yüksek performans kategorileri.
enum BroadcastPerformance {
  excellent,    // Mükemmel
  good,         // İyi
  fair,         // Orta
  poor,         // Zayıf
}

String broadcastPerformanceLabel(BroadcastPerformance perf) {
  switch (perf) {
    case BroadcastPerformance.excellent:
      return 'Mükemmel';
    case BroadcastPerformance.good:
      return 'İyi';
    case BroadcastPerformance.fair:
      return 'Orta';
    case BroadcastPerformance.poor:
      return 'Zayıf';
  }
}
