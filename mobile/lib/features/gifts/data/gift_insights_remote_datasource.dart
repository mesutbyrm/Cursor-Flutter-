import 'package:dio/dio.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/gift_collection.dart';
import '../domain/gift_leaderboard_entry.dart';
import '../domain/supporter_badge.dart';

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

  /// Destekçi rozeti (Bronz → Efsane). userId null ise kendi rozetim.
  Future<SupporterBadge?> fetchBadge({String? userId}) async {
    final path = userId == null || userId.isEmpty
        ? '/api/gifts/insights/me/badge'
        : '/api/gifts/insights/badge/$userId';
    final res = await _dio.safeGet<dynamic>(path);
    final body = res.data;
    if (body is Map) return SupporterBadge.fromJson(asJsonMap(body));
    return null;
  }

  /// Hediye koleksiyonu (gönderilen/alınan, tamamlanma %).
  Future<GiftCollection> fetchCollection(String userId) async {
    final res =
        await _dio.safeGet<dynamic>('/api/gifts/insights/collection/$userId');
    final body = res.data;
    if (body is Map) return GiftCollection.fromJson(asJsonMap(body));
    return const GiftCollection();
  }

  /// Hediye albümü (alınan benzersiz hediyeler).
  Future<GiftAlbum> fetchAlbum(String userId) async {
    final res =
        await _dio.safeGet<dynamic>('/api/gifts/insights/album/$userId');
    final body = res.data;
    if (body is Map) return GiftAlbum.fromJson(asJsonMap(body));
    return const GiftAlbum();
  }

  /// Efsane İlk Destekçi rozeti — bir bağlamdaki ilk hediyeyi gönderen.
  Future<FirstGifter?> fetchFirstGifter({
    required String context,
    required String contextId,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      '/api/gifts/insights/first-gifter/$context/$contextId',
    );
    final body = res.data;
    if (body is Map) return FirstGifter.fromResponse(asJsonMap(body));
    return null;
  }
}
