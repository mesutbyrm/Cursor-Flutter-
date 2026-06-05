import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/home_banner_entity.dart';
import '../../domain/entities/home_game_entity.dart';
import '../../domain/entities/home_trend_video_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../../domain/entities/online_advisor_entity.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<HomeBannerEntity>> fetchBanners() async {
    for (final path in [
      ApiEndpoints.homeBanners,
      ApiEndpoints.socialAnnouncements,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final items = _itemsFromBody(res.data);
        if (items.isNotEmpty) return items.map(_mapBanner).toList();
      } catch (_) {}
    }
    return const [];
  }

  Future<List<LiveFortuneTellerEntity>> fetchLiveFortuneTellers() async {
    for (final path in [
      ApiEndpoints.fortuneTellers,
      ApiEndpoints.homeAdvisorsOnline,
      ApiEndpoints.socialFortuneTellers,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final items = _itemsFromBody(res.data, keys: const [
          'items',
          'tellers',
          'advisors',
          'fortuneTellers',
          'data',
          'results',
        ]);
        if (items.isNotEmpty) {
          final tellers = items
              .map(_mapLiveFortuneTeller)
              .where((t) => t.id.isNotEmpty)
              .toList();
          tellers.sort((a, b) {
            if (a.isOnline != b.isOnline) {
              return a.isOnline ? -1 : 1;
            }
            return b.rating.compareTo(a.rating);
          });
          return tellers;
        }
      } catch (_) {}
    }
    return const [];
  }

  Future<({String sessionId, String status})?> createFortuneTellerSession(
    String tellerId,
  ) async {
    final id = tellerId.trim();
    if (id.isEmpty) return null;
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneTellerSession,
        data: {'tellerId': id, 'fortuneTellerId': id},
      );
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final sessionId = pick(data, ['sessionId', 'id'])?.toString() ??
          (data['session'] is Map
              ? pick(asJsonMap(data['session']), ['id', 'sessionId'])?.toString()
              : null);
      final status = pick(data, ['status'])?.toString() ??
          (data['session'] is Map
              ? pick(asJsonMap(data['session']), ['status'])?.toString()
              : 'pending');
      if (sessionId == null || sessionId.isEmpty) return null;
      return (sessionId: sessionId, status: status ?? 'pending');
    } catch (_) {
      return null;
    }
  }

  Future<LiveFortuneTellerEntity?> fetchLiveFortuneTeller(String id) async {
    final key = id.trim();
    if (key.isEmpty) return null;
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneTeller(key));
      final body = res.data;
      if (body is Map) {
        final map = asJsonMap(body);
        final data = map['data'] is Map ? asJsonMap(map['data']) : map;
        final teller = data['teller'] ?? data['fortuneTeller'] ?? data;
        return _mapLiveFortuneTeller(teller);
      }
    } catch (_) {}
    final list = await fetchLiveFortuneTellers();
    for (final t in list) {
      if (t.id == key) return t;
    }
    return null;
  }

  Future<List<OnlineAdvisorEntity>> fetchOnlineAdvisors() async {
    final tellers = await fetchLiveFortuneTellers();
    if (tellers.isNotEmpty) {
      return tellers
          .map(
            (t) => OnlineAdvisorEntity(
              id: t.id,
              name: t.name,
              category: t.displayCategory,
              avatarUrl: t.avatarUrl,
              isOnline: t.isOnline,
              rating: t.rating,
              viewerCount: t.reviewCount,
              specialties: t.specialties,
            ),
          )
          .toList();
    }
    return const [];
  }

  Future<List<HomeGameEntity>> fetchGames() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.homeGames);
      final items = _itemsFromBody(res.data);
      if (items.isNotEmpty) {
        return items.map(_mapGame).where((g) => g.id.isNotEmpty).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<List<DailyRewardEntity>> fetchDailyRewards() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.homeDailyRewards);
      final items = _itemsFromBody(res.data);
      return items.map(_mapDailyReward).where((r) => r.id.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<HomeTrendVideoEntity>> fetchTrendVideos() async {
    for (final path in [ApiEndpoints.trendVideos]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final items = _itemsFromBody(
          res.data,
          keys: const ['videos', 'items', 'posts', 'data', 'results'],
        );
        if (items.isNotEmpty) {
          return items
              .map(_mapTrendVideo)
              .where((v) => v.id.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  Future<int?> fetchUnreadNotifications() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.notificationsUnread);
      final map = asJsonMap(res.data);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final countRaw = pick(data, ['count', 'unread', 'unreadCount']);
      if (countRaw != null) return asInt(countRaw);
    } catch (_) {}
    if (Env.useMobileAuth) {
      try {
        final res = await _dio.safeGet<dynamic>(
          ApiEndpoints.messages,
          query: {'unreadCount': 'true'},
        );
        final map = asJsonMap(res.data);
        final countRaw = pick(map, ['unreadCount', 'count', 'unread']);
        if (countRaw != null) return asInt(countRaw);
      } catch (_) {}
    }
    return null;
  }

  List<dynamic> _itemsFromBody(
    dynamic body, {
    List<String> keys = const ['items', 'banners', 'data', 'results'],
  }) {
    if (body is List) return body;
    if (body is! Map) return const [];
    final map = asJsonMap(body);
    if (map['success'] == true && map['data'] != null) {
      final data = map['data'];
      if (data is List) return data;
      if (data is Map) {
        for (final k in keys) {
          final v = data[k];
          if (v is List) return v;
        }
      }
    }
    for (final k in keys) {
      final v = map[k];
      if (v is List) return v;
    }
    return const [];
  }

  HomeBannerEntity _mapBanner(dynamic raw) {
    final m = asJsonMap(raw);
    final gradientRaw = m['gradient'];
    List<int> gradient = const [0xFF2A1548, 0xFF7B4DFF];
    if (gradientRaw is List && gradientRaw.length >= 2) {
      gradient = gradientRaw
          .take(2)
          .map((e) => _parseColorInt(e) ?? 0xFF7B4DFF)
          .toList();
    }
    final actionsRaw = m['quickActions'] ?? m['actions'];
    final actions = <HomeBannerQuickAction>[];
    if (actionsRaw is List) {
      for (final a in actionsRaw) {
        final am = asJsonMap(a);
        final id = _str(am, ['id', 'slug']) ?? '';
        if (id.isEmpty) continue;
        actions.add(
          HomeBannerQuickAction(
            id: id,
            label: _str(am, ['label', 'title', 'name']) ?? id,
            route: _str(am, ['route', 'path', 'href']),
          ),
        );
      }
    }
    return HomeBannerEntity(
      id: _str(m, ['id', '_id']) ?? '',
      title: _str(m, ['title', 'headline', 'name']) ?? 'CanlıFal',
      subtitle: _str(m, ['subtitle', 'body', 'description']),
      ctaLabel: _str(m, ['ctaLabel', 'cta', 'buttonLabel']),
      ctaRoute: _str(m, ['ctaRoute', 'ctaPath', 'link', 'url']),
      imageUrl: _str(m, ['imageUrl', 'image', 'thumbnailUrl', 'icon']),
      gradient: gradient,
      quickActions: actions,
    );
  }

  LiveFortuneTellerEntity _mapLiveFortuneTeller(dynamic raw) {
    final m = asJsonMap(raw);
    final user = asJsonMap(m['user'] ?? m['profile']);
    final online = m['isOnline'] == true ||
        m['online'] == true ||
        m['status']?.toString().toLowerCase() == 'online' ||
        m['canGoOnline'] == true;
    final specs = _stringList(m['specialties'] ?? m['tags'] ?? user['specialties']);
    return LiveFortuneTellerEntity(
      id: _str(m, ['id', '_id', 'tellerId', 'userId']) ??
          _str(user, ['id', 'userId']) ??
          '',
      name: _str(m, ['displayName', 'name', 'username']) ??
          _str(user, ['displayName', 'name', 'username']) ??
          'Falcı',
      bio: _str(m, ['bio', 'description', 'about']) ?? _str(user, ['bio']),
      avatarUrl: _str(m, [
            'avatarUrl',
            'image',
            'avatar',
            'photoUrl',
            'profileImage',
          ]) ??
          _str(user, ['avatarUrl', 'image', 'avatar']),
      isOnline: online,
      rating: _dbl(m, ['rating', 'score', 'averageRating']) != 0
          ? _dbl(m, ['rating', 'score', 'averageRating'])
          : _dbl(user, ['rating', 'score']),
      reviewCount: asInt(
        pick(m, ['reviewCount', 'reviews', 'totalReviews', 'viewerCount']),
      ),
      pricePerMinute: asInt(
        pick(m, [
          'pricePerMinute',
          'pricePerSession',
          'sessionPrice',
          'price',
          'minutePrice',
        ]),
      ),
      level: _str(m, ['level', 'tier', 'tellerLevel']),
      specialties: specs,
      category: _advisorCategory(m) ?? _advisorCategory(user),
    );
  }

  OnlineAdvisorEntity _mapAdvisor(dynamic raw) {
    final m = asJsonMap(raw);
    final online = m['isOnline'] == true ||
        m['online'] == true ||
        m['status'] == 'online';
    return OnlineAdvisorEntity(
      id: _str(m, ['id', '_id', 'userId']) ?? '',
      name: _str(m, ['name', 'displayName', 'username']) ?? 'Falcı',
      category: _advisorCategory(m),
      avatarUrl: _str(m, ['avatarUrl', 'image', 'avatar', 'photoUrl']),
      isOnline: online,
      rating: _dbl(m, ['rating', 'score']),
      viewerCount: asInt(pick(m, ['viewerCount', 'viewers', 'audience'])),
      specialties: _stringList(m['specialties']),
    );
  }

  HomeGameEntity _mapGame(dynamic raw) {
    final m = asJsonMap(raw);
    return HomeGameEntity(
      id: _str(m, ['id', 'slug']) ?? '',
      title: _str(m, ['title', 'name', 'label']) ?? '',
      icon: _str(m, ['icon', 'emoji']),
      route: _str(m, ['route', 'path', 'deepLink']),
      accentColorArgb: _parseColorInt(m['accentColor'] ?? m['color']),
    );
  }

  HomeTrendVideoEntity _mapTrendVideo(dynamic raw) {
    final m = asJsonMap(raw);
    final badges = ['POPÜLER', 'EZEL', 'YENİ', 'TREND'];
    final idx = m.hashCode.abs() % badges.length;
    return HomeTrendVideoEntity(
      id: _str(m, ['id', '_id']) ?? '',
      title: _str(m, ['title', 'name', 'content']) ?? 'Video',
      channelName: _str(m, ['channelName', 'author', 'username']) ??
          _str(asJsonMap(m['channel'] ?? m['celebrity']), ['name', 'displayName']) ??
          'Canlifal',
      thumbnailUrl: _str(m, [
        'thumbnailUrl',
        'thumbnail',
        'imageUrl',
        'coverUrl',
        'image',
      ]),
      duration: _str(m, ['duration', 'length']) ?? '0:30',
      badge: _str(m, ['badge', 'tag', 'label']) ?? badges[idx],
      viewCount: asInt(pick(m, ['viewCount', 'views', 'viewers'])),
    );
  }

  DailyRewardEntity _mapDailyReward(dynamic raw) {
    final m = asJsonMap(raw);
    return DailyRewardEntity(
      id: _str(m, ['id']) ?? '',
      title: _str(m, ['title', 'name']) ?? '',
      description: _str(m, ['description', 'body']),
      claimed: m['claimed'] == true,
      rewardJeton: asInt(pick(m, ['rewardJeton', 'jeton', 'amount'])),
      route: _str(m, ['route', 'path']),
    );
  }

  List<String> _stringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (v is String && v.isNotEmpty) return [v];
    return const [];
  }

  String? _advisorCategory(Map<String, dynamic> m) {
    final direct = _str(m, ['category', 'specialty', 'title']);
    if (direct != null) return direct;
    final specs = m['specialties'];
    if (specs is List && specs.isNotEmpty) {
      return specs.first.toString();
    }
    return null;
  }

  String? _str(Map<String, dynamic> m, List<String> keys) {
    final v = pick(m, keys);
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  double _dbl(Map<String, dynamic> m, List<String> keys) {
    final v = pick(m, keys);
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  int? _parseColorInt(dynamic v) {
    if (v is int) return v;
    if (v is String) {
      var s = v.trim();
      if (s.startsWith('#')) s = s.substring(1);
      if (s.startsWith('0x')) return int.tryParse(s.substring(2), radix: 16);
      final parsed = int.tryParse(s, radix: 16);
      if (parsed != null) {
        return s.length <= 6 ? (0xFF000000 | parsed) : parsed;
      }
    }
    return null;
  }
}

/// Wallet balance shortcut for header (production + self-hosted).
Future<int> fetchWalletJetonBalance(Dio dio) async {
  if (Env.useMobileAuth) {
    try {
      final me = await dio.safeGet<dynamic>(ApiEndpoints.me);
      final map = asJsonMap(me.data);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final user = data['user'] is Map ? asJsonMap(data['user']) : data;
      return asInt(pick(user, ['coins', 'jeton', 'coinBalance', 'balance']));
    } catch (_) {}
  }
  for (final path in [ApiEndpoints.userCredits, ApiEndpoints.wallet]) {
    try {
      final res = await dio.safeGet<dynamic>(path);
      final map = asJsonMap(res.data);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      return asInt(pick(data, ['jeton', 'coins', 'balance', 'cfc']));
    } catch (_) {}
  }
  return 0;
}
