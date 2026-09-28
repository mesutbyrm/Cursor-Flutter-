import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Canlı yayın kontrol — aktif yayınlar `GET /api/video-streams` (status=live).
///
/// `/api/live/admin/*` backend'de yok; `/api/admin/video-streams` yalnız web
/// oturumu kabul eder. Kart alanları backend öğesinden eşlenir.
final adminActiveBroadcastsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final dio = ref.watch(dioProvider);
      try {
        final res = await dio.safeGet<dynamic>(
          ApiEndpoints.videoStreams,
          query: {'limit': '100'},
        );
        final body = res.data;
        final raw = body is Map ? (body['items'] ?? body['streams']) : body;
        if (raw is! List) return [];
        return [
          for (final e in raw)
            if (e is Map)
              {
                'id': e['id']?.toString(),
                'broadcaster_name':
                    e['streamerName'] ??
                    (e['user'] is Map ? (e['user'] as Map)['name'] : null),
                'title': e['title'],
                'viewer_count': e['viewerCount'] is int ? e['viewerCount'] : 0,
                'started_at': e['startedAt']?.toString(),
              },
        ];
      } catch (e) {
        return [];
      }
    });

/// Aktif yayın sayısı.
final adminActiveBroadcastCountProvider = Provider<int>((ref) {
  final broadcasts = ref.watch(adminActiveBroadcastsProvider).valueOrNull ?? [];
  return broadcasts.length;
});

/// Uyarı gerektiren yayınlar — backend'de işaretli yayın listesi yok.
final adminFlaggedBroadcastsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) async => const [],
    );

/// Uyarılı yayın sayısı.
final adminFlaggedBroadcastCountProvider = Provider<int>((ref) {
  final broadcasts =
      ref.watch(adminFlaggedBroadcastsProvider).valueOrNull ?? [];
  return broadcasts.length;
});

/// Yayın moderasyon işlemleri.
enum BroadcastModerationAction {
  warning, // Uyarı gönder
  suspend, // Yayını askıya al
  terminate, // Yayını sonlandır
  ban, // Yayıncıyı yasakla
  timeout, // Geçici mute
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
  excellent, // Mükemmel
  good, // İyi
  fair, // Orta
  poor, // Zayıf
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
