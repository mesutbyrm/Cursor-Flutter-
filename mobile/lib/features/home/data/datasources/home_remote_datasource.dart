import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/home_banner_entity.dart';
import '../../domain/entities/home_game_entity.dart';
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

  Future<List<OnlineAdvisorEntity>> fetchOnlineAdvisors() async {
    for (final path in [
      ApiEndpoints.homeAdvisorsOnline,
      ApiEndpoints.socialFortuneTellers,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final items = _itemsFromBody(res.data, keys: const [
          'items',
          'tellers',
          'advisors',
          'data',
        ]);
        if (items.isNotEmpty) {
          return items
              .map(_mapAdvisor)
              .where((a) => a.id.isNotEmpty)
              .toList();
        }
      } catch (_) {}
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

  Future<int?> fetchUnreadNotifications() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.notificationsUnread);
      final map = asJsonMap(res.data);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final countRaw = pick(data, ['count', 'unread', 'unreadCount']);
      if (countRaw != null) return asInt(countRaw);
    } catch (_) {}
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
