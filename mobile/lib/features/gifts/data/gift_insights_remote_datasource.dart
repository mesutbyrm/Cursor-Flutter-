import 'package:dio/dio.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/gift_collection.dart';
import '../domain/gift_feed_item.dart';
import '../domain/gift_leaderboard_entry.dart';
import '../domain/gift_mission.dart';
import '../domain/gift_sender_map.dart';
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

  /// Canlı hediye akışı (gizli hediyeler hariç). context/contextId opsiyonel.
  Future<List<GiftFeedItem>> fetchFeed({
    String? context,
    String? contextId,
    int limit = 50,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      '/api/gifts/insights/feed',
      query: {
        if (context != null) 'context': context,
        if (contextId != null) 'contextId': contextId,
        'limit': limit,
      },
    );
    return _parseFeed(res.data);
  }

  List<GiftFeedItem> _parseFeed(dynamic body) {
    dynamic raw = body;
    if (body is Map) raw = asJsonMap(body)['items'] ?? asJsonMap(body)['data'];
    if (raw is! List) return const [];
    final out = <GiftFeedItem>[];
    for (final e in raw) {
      if (e is Map) out.add(GiftFeedItem.fromJson(asJsonMap(e)));
    }
    return out;
  }

  /// Gönderen haritası (şehir/ülke bazlı yoğunluk).
  Future<GiftSenderMap> fetchSenderMap({
    String period = 'weekly',
    String scope = 'tr',
  }) async {
    final res = await _dio.safeGet<dynamic>(
      '/api/gifts/insights/map',
      query: {'period': period, 'scope': scope},
    );
    final body = res.data;
    if (body is Map) return GiftSenderMap.fromJson(asJsonMap(body));
    return const GiftSenderMap();
  }

  /// Bana özel hediye önerileri (AI/sezgisel).
  Future<List<GiftRecommendation>> fetchRecommendations({String? context}) async {
    final res = await _dio.safeGet<dynamic>(
      '/api/gifts/insights/me/recommendations',
      query: {if (context != null) 'context': context},
    );
    dynamic raw = res.data;
    if (raw is Map) {
      raw = asJsonMap(raw)['recommendations'] ??
          asJsonMap(raw)['items'] ??
          asJsonMap(raw)['data'];
    }
    if (raw is! List) return const [];
    final out = <GiftRecommendation>[];
    for (final e in raw) {
      if (e is Map) out.add(GiftRecommendation.fromJson(asJsonMap(e)));
    }
    return out;
  }

  /// Aktif görevler + bugünkü ilerlemem (birleştirilmiş).
  Future<List<GiftMission>> fetchMissions() async {
    // Tanımlar (public) + ilerleme (me) birleştirilir.
    final defsRes = await _dio.safeGet<dynamic>('/api/gifts/missions');
    final defs = _parseMissions(defsRes.data);
    Map<String, GiftMission> mine = {};
    try {
      final meRes = await _dio.safeGet<dynamic>('/api/gifts/missions/me');
      for (final m in _parseMissions(meRes.data)) {
        if (m.id.isNotEmpty) mine[m.id] = m;
      }
    } catch (_) {
      // giriş yoksa yalnızca tanımlar gösterilir
    }
    if (mine.isEmpty) return defs;
    return [
      for (final d in defs)
        mine[d.id] == null
            ? d
            : GiftMission(
                id: d.id,
                title: d.title.isNotEmpty ? d.title : mine[d.id]!.title,
                description: d.description ?? mine[d.id]!.description,
                target: d.target > 0 ? d.target : mine[d.id]!.target,
                progress: mine[d.id]!.progress,
                reward: d.reward > 0 ? d.reward : mine[d.id]!.reward,
                rewardLabel: d.rewardLabel ?? mine[d.id]!.rewardLabel,
                completed: mine[d.id]!.completed,
                claimed: mine[d.id]!.claimed,
              ),
    ];
  }

  List<GiftMission> _parseMissions(dynamic body) {
    dynamic raw = body;
    if (body is Map) {
      raw = asJsonMap(body)['missions'] ?? asJsonMap(body)['data'] ?? body;
    }
    if (raw is! List) return const [];
    final out = <GiftMission>[];
    for (final e in raw) {
      if (e is Map) out.add(GiftMission.fromJson(asJsonMap(e)));
    }
    return out;
  }

  /// Görev ödülünü al.
  Future<bool> claimMission(String id) async {
    final res = await _dio.safePost<dynamic>('/api/gifts/missions/$id/claim');
    final body = res.data;
    if (body is Map) {
      final ok = asJsonMap(body)['success'];
      return ok is bool ? ok : true;
    }
    return true;
  }
}
