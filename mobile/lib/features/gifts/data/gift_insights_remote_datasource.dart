import 'package:dio/dio.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/gift_leaderboard_entry.dart';

/// Premium Gift Ecosystem — insights uçları (liderlik, koleksiyon, rozet…).
/// Backend: `/api/gifts/insights/*`.
class GiftInsightsRemoteDataSource {
  GiftInsightsRemoteDataSource(this._dio);

  final Dio _dio;

  /// Liderlik tablosu — gönderenler/alıcılar; TR/Dünya; gün→tüm zamanlar; kategori.
  Future<List<GiftLeaderboardEntry>> fetchLeaderboard({
    String type = 'senders', // senders | receivers
    String period = 'weekly', // daily | weekly | monthly | yearly | all
    String scope = 'tr', // tr | world
    String context = 'all', // all | live_stream | voice_room | video | short_video | fortune
    int limit = 100,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      '/api/gifts/insights/leaderboard',
      query: {
        'type': type,
        'period': period,
        'scope': scope,
        'context': context,
        'limit': limit,
      },
    );
    final body = res.data;
    dynamic raw;
    if (body is Map) {
      final m = Map<String, dynamic>.from(body);
      raw = m['entries'] ?? m['data'] ?? m['leaderboard'] ?? m['items'];
    } else {
      raw = body;
    }
    if (raw is! List) return const [];
    var rank = 0;
    return raw.whereType<Map>().map((e) {
      final json = asJsonMap(e);
      final entry = GiftLeaderboardEntry.fromJson(json);
      rank++;
      // Sunucu rank vermezse sıraya göre ata.
      return entry.rank > 0
          ? entry
          : GiftLeaderboardEntry(
              rank: rank,
              displayName: entry.displayName,
              userId: entry.userId,
              totalCoins: entry.totalCoins,
              giftCount: entry.giftCount,
              avatarUrl: entry.avatarUrl,
              city: entry.city,
              country: entry.country,
              level: entry.level,
              badge: entry.badge,
            );
    }).toList();
  }
}
