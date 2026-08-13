import 'package:dio/dio.dart';

import '../../../../core/images/canlifal_image_urls.dart';
import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../models/mobile_compound_models.dart';
import 'mobile_compound_remote_datasource.dart';
import '../../domain/entities/home_banner_entity.dart';
import '../../domain/entities/home_fortune_card_entity.dart';
import '../../domain/entities/home_game_entity.dart';
import '../../domain/entities/home_page_button_entity.dart';
import '../../domain/entities/home_trend_video_entity.dart';
import '../../domain/entities/online_advisor_entity.dart';
import '../../domain/home_site_catalog.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._dio)
      : _compound = MobileCompoundRemoteDataSource(_dio);

  final Dio _dio;
  final MobileCompoundRemoteDataSource _compound;

  Future<MobileHomeBundle?> fetchMobileHome({bool force = false}) =>
      _compound.fetchHome(force: force);

  Future<List<HomeBannerEntity>> fetchBanners() async {
    final compound = await fetchMobileHome();
    if (compound != null && compound.banners.isNotEmpty) {
      return compound.banners;
    }
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

  /// `GET /api/homepage-ticker` — kayan yazı satırları (API dokümanı §23).
  Future<List<String>> fetchHomepageTicker() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.homepageTicker);
      return _tickerLinesFromBody(res.data);
    } catch (_) {
      return const [];
    }
  }

  List<String> _tickerLinesFromBody(dynamic body) {
    final lines = <String>[];
    void add(String? raw) {
      final t = raw?.trim() ?? '';
      if (t.isEmpty) return;
      if (!lines.contains(t)) lines.add(t);
    }

    if (body is String) {
      add(body);
      return lines;
    }
    if (body is List) {
      for (final item in body) {
        if (item is String) {
          add(item);
        } else if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          add(
            (m['message'] ??
                    m['text'] ??
                    m['title'] ??
                    m['content'] ??
                    m['line'] ??
                    m['ticker'])
                ?.toString(),
          );
        }
      }
      return lines;
    }
    if (body is Map) {
      final m = Map<String, dynamic>.from(body);
      final nested = m['items'] ??
          m['tickers'] ??
          m['messages'] ??
          m['data'] ??
          m['lines'];
      if (nested != null) return _tickerLinesFromBody(nested);
      add(
        (m['message'] ?? m['text'] ?? m['title'] ?? m['content'])?.toString(),
      );
    }
    return lines;
  }

  Future<List<OnlineAdvisorEntity>> fetchOnlineAdvisors() async {
    final compound = await fetchMobileHome();
    if (compound != null && compound.advisors.isNotEmpty) {
      return compound.advisors;
    }
    for (final path in [
      ApiEndpoints.homeAdvisorsOnline,
      ApiEndpoints.fortuneTellers,
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
          return items.map(_mapAdvisor).where((a) => a.id.isNotEmpty).toList();
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

  /// `GET /api/homepage-buttons` — ana sayfa hızlı erişim butonları.
  Future<List<HomePageButtonEntity>> fetchHomepageButtons() async {
    final compound = await fetchMobileHome();
    if (compound != null && compound.homepageButtons.isNotEmpty) {
      return compound.homepageButtons;
    }
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.homepageButtons);
      final items = _itemsFromBody(
        res.data,
        keys: const ['buttons', 'homepageButtons', 'items', 'data'],
      );
      final buttons = items
          .map(_mapHomepageButton)
          .where((b) => b.id.isNotEmpty && b.isActive)
          .toList();
      buttons.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return buttons;
    } catch (_) {
      return const [];
    }
  }

  /// `GET /api/fan-clubs` — popüler fan kulüpleri.
  Future<List<HomeFanClubItem>> fetchFanClubs() async {
    for (final path in [ApiEndpoints.fanClubsPopular, ApiEndpoints.fanClubs]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final items = _itemsFromBody(
          res.data,
          keys: const ['fanClubs', 'clubs', 'items', 'data', 'results'],
        );
        if (items.isEmpty) continue;
        return items
            .map(_mapFanClub)
            .where((c) => c.id.isNotEmpty && c.title.isNotEmpty)
            .toList();
      } catch (_) {}
    }
    return const [];
  }

  /// `POST /api/horoscope/daily` — günlük burç yorumu.
  Future<String?> fetchDailyHoroscope(String zodiacSign) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.horoscopeDaily,
        data: {'zodiacSign': zodiacSign},
      );
      return _horoscopeTextFromBody(res.data);
    } catch (_) {
      return null;
    }
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
    // Ana akış önce (daha güvenilir); keşfet yedek.
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.shortVideos,
        query: {'limit': 12, 'tab': 'foryou'},
      );
      final shorts = _shortVideosFromBody(res.data)
          .map(_mapShortVideoToTrend)
          .where((v) => v.id.isNotEmpty && !v.isYoutubeSource)
          .toList();
      if (shorts.isNotEmpty) return shorts;
    } catch (_) {}

    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.shortVideosExplore,
        query: {'limit': 12},
      );
      final m = _unwrapExploreBody(res.data);
      final shorts = _shortVideosFromExplore(m)
          .map(_mapShortVideoToTrend)
          .where((v) => v.id.isNotEmpty && !v.isYoutubeSource)
          .toList();
      if (shorts.isNotEmpty) return shorts;
    } catch (_) {}

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
              .where((v) => v.id.isNotEmpty && !v.isYoutubeSource)
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  List<dynamic> _shortVideosFromBody(dynamic body) {
    if (body is! Map) return const [];
    final m = asJsonMap(body);
    final data = m['success'] == true && m['data'] is Map
        ? asJsonMap(m['data'])
        : m;
    final raw = data['videos'];
    if (raw is List) return raw;
    return const [];
  }

  Map<String, dynamic>? _unwrapExploreBody(dynamic body) {
    if (body is! Map) return null;
    final m = asJsonMap(body);
    if (m['success'] == true && m['data'] is Map) {
      return asJsonMap(m['data']);
    }
    return m;
  }

  List<dynamic> _shortVideosFromExplore(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final raw = data['videos'];
    if (raw is List) return raw;
    return const [];
  }

  HomeTrendVideoEntity _mapShortVideoToTrend(dynamic raw) {
    final m = asJsonMap(raw);
    final authorRaw = pick(m, ['author', 'user']);
    var channel = 'Canlifal';
    if (authorRaw is Map) {
      final am = asJsonMap(authorRaw);
      channel = _str(am, ['displayName', 'username', 'name']) ?? channel;
    }
    final desc = _str(m, ['description', 'caption'])?.trim();
    final dur = pick(m, ['durationSec', 'duration_sec']);
    var durationStr = '';
    if (dur is num && dur > 0) {
      final sec = dur.round();
      final m = sec ~/ 60;
      final s = sec % 60;
      durationStr = '$m:${s.toString().padLeft(2, '0')}';
    }
    return HomeTrendVideoEntity(
      id: _str(m, ['id', '_id']) ?? '',
      title: (desc != null && desc.isNotEmpty) ? desc : channel,
      channelName: channel,
      thumbnailUrl: _resolveTrendThumb(m),
      duration: durationStr,
      viewCount: asInt(pick(m, ['viewsCount', 'views_count', 'viewCount'])),
      likesCount: asInt(pick(m, [
        'likesCount',
        'likes_count',
        'likeCount',
        'likes',
      ])),
      videoUrl: CanlifalImageUrls.resolve(
        _str(m, ['videoUrl', 'video_url']),
      ),
      badge: 'YENİ',
    );
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

  /// Dış datasource'lar için JSON → entity (canlı falcı modülü).
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
    final videoUrl = _str(m, [
      'videoUrl',
      'video_url',
      'playbackUrl',
      'url',
      'youtubeUrl',
    ]);
    return HomeTrendVideoEntity(
      id: _str(m, ['id', '_id']) ?? '',
      title: _str(m, ['title', 'name', 'content']) ?? 'Video',
      channelName: _str(m, ['channelName', 'author', 'username']) ??
          _str(asJsonMap(m['channel'] ?? m['celebrity']), ['name', 'displayName']) ??
          'Canlifal',
      thumbnailUrl: _resolveTrendThumb(m),
      duration: _str(m, ['duration', 'length']) ?? '0:30',
      badge: _str(m, ['badge', 'tag', 'label']) ?? badges[idx],
      viewCount: asInt(pick(m, ['viewCount', 'views', 'viewers'])),
      likesCount: asInt(pick(m, ['likesCount', 'likes_count', 'likeCount', 'likes'])),
      videoUrl: CanlifalImageUrls.resolve(videoUrl),
    );
  }

  String? _resolveTrendThumb(Map<String, dynamic> m) {
    final direct = CanlifalImageUrls.resolve(
      _str(m, [
        'thumbnailUrl',
        'thumbnail_url',
        'thumbnail',
        'coverUrl',
        'cover_url',
        'imageUrl',
        'image',
        'thumbUrl',
        'posterUrl',
        'cloud_storage_thumb',
        'thumbPath',
      ]),
    );
    if (direct.isNotEmpty) return direct;
    final video = _str(m, ['videoUrl', 'video_url', 'playbackUrl']);
    final derived = CanlifalImageUrls.thumbFromVideoUrl(video);
    if (derived != null && derived.isNotEmpty) return derived;
    return null;
  }

  HomePageButtonEntity _mapHomepageButton(dynamic raw) {
    final m = asJsonMap(raw);
    return HomePageButtonEntity(
      id: _str(m, ['id', '_id', 'slug']) ?? '',
      label: _str(m, ['label', 'title', 'name']) ?? '',
      iconUrl: CanlifalImageUrls.resolve(
        _str(m, ['iconUrl', 'icon', 'imageUrl', 'image']),
      ),
      linkUrl: _str(m, ['linkUrl', 'href', 'route', 'path', 'url']),
      sortOrder: asInt(pick(m, ['sortOrder', 'order', 'position'])) ?? 0,
      isActive: m['isActive'] != false && m['isVisible'] != false,
    );
  }

  HomeFanClubItem _mapFanClub(dynamic raw) {
    final m = asJsonMap(raw);
    final slug = _str(m, ['slug', 'id']);
    final routeRaw = _str(m, ['route', 'path', 'url']);
    final route = routeRaw != null && routeRaw.startsWith('/')
        ? routeRaw
        : (slug != null && slug.isNotEmpty
            ? '/fan-club/$slug'
            : '/fan-club-hub');
    return HomeFanClubItem(
      id: _str(m, ['id', '_id', 'slug']) ?? '',
      title: _str(m, ['title', 'name', 'displayName']) ?? '',
      subtitle: _str(m, ['subtitle', 'description', 'category']),
      imageUrl: CanlifalImageUrls.resolve(
        _str(m, ['imageUrl', 'image', 'coverUrl', 'avatarUrl', 'logoUrl']),
      ),
      route: route,
      memberCount: asInt(
        pick(m, ['memberCount', 'membersCount', 'followersCount']),
      ),
    );
  }

  String? _horoscopeTextFromBody(dynamic body) {
    if (body is String) {
      final t = body.trim();
      return t.isEmpty ? null : t;
    }
    if (body is! Map) return null;
    final m = asJsonMap(body);
    final data = m['data'] is Map ? asJsonMap(m['data']) : m;
    final text = pick(data, [
      'horoscope',
      'text',
      'content',
      'message',
      'reading',
      'summary',
      'description',
    ]);
    if (text != null) {
      final s = text.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
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

  /// canlifal.com ana sayfa fal vitrin — web `/` ile aynı kart listesi.
  Future<List<HomeFortuneCardEntity>> fetchHomepageFortuneCards() async {
    final compound = await fetchMobileHome();
    if (compound != null && compound.fortuneCards.isNotEmpty) {
      return compound.fortuneCards;
    }
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.homepageFortuneCards);
      final items = _itemsFromBody(res.data, keys: const ['cards', 'items']);
      if (items.isEmpty) return const [];
      return items
          .map((j) => _mapHomeFortuneCard(j))
          .where((c) => c.title.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  HomeFortuneCardEntity _mapHomeFortuneCard(Map<String, dynamic> m) {
    final href = _str(m, const ['href', 'url', 'link']) ?? '';
    var slug = _str(m, const ['slug', 'fortuneSlug']) ?? '';
    if (slug.isEmpty && href.contains('/')) {
      slug = href.split('/').where((s) => s.isNotEmpty).last;
    }
    return HomeFortuneCardEntity(
      id: _str(m, const ['id']) ?? slug,
      title: _str(m, const ['name', 'title']) ?? '',
      slug: slug,
      icon: _str(m, const ['icon', 'emoji']) ?? '🔮',
      imageUrl: CanlifalImageUrls.resolve(
        _str(m, const ['image', 'imageUrl', 'thumbnail']),
      ),
      routePath: href.isNotEmpty ? href : null,
    );
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
