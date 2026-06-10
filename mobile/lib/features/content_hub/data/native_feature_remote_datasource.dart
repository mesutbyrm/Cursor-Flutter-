import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/native_feature_item.dart';

class NativeFeatureRemoteDataSource {
  NativeFeatureRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<NativeFeatureItem>> fetch(NativeFeatureHubKind kind) {
    return switch (kind) {
      NativeFeatureHubKind.games => _fetchGames(),
      NativeFeatureHubKind.dreams => _fetchDreams(),
      NativeFeatureHubKind.blog => _fetchBlog(),
      NativeFeatureHubKind.celebrities => _fetchCelebrities(),
      NativeFeatureHubKind.fanClub => _fetchFanClubs(),
      NativeFeatureHubKind.adRewards => Future.value(const []),
    };
  }

  Future<List<NativeFeatureItem>> _fetchGames() async {
    final items = <NativeFeatureItem>[];
    items.addAll(
      await _fetchPath(
        ApiEndpoints.homeGames,
        fallbackIcon: Icons.sports_esports_rounded,
        fallbackRoute: '/games-hub',
      ),
    );
    items.addAll(
      await _fetchPath(
        ApiEndpoints.tournaments,
        fallbackIcon: Icons.emoji_events_rounded,
        fallbackRoute: '/games-hub',
        badge: 'Turnuva',
      ),
    );
    return _dedupe(items);
  }

  Future<List<NativeFeatureItem>> _fetchDreams() async {
    final items = <NativeFeatureItem>[];
    items.addAll(
      await _fetchPath(
        ApiEndpoints.dreams,
        fallbackIcon: Icons.nights_stay_rounded,
        fallbackRoute: '/dreams-hub',
      ),
    );
    items.addAll(
      await _fetchPath(
        ApiEndpoints.dreamSymbols,
        fallbackIcon: Icons.auto_stories_rounded,
        fallbackRoute: '/dreams-hub',
        badge: 'Sözlük',
      ),
    );
    items.addAll(
      await _fetchPath(
        ApiEndpoints.dreamContest,
        fallbackIcon: Icons.how_to_vote_rounded,
        fallbackRoute: '/dreams-hub',
        badge: 'Yarışma',
      ),
    );
    return _dedupe(items);
  }

  Future<List<NativeFeatureItem>> _fetchBlog() async {
    final recent = await _fetchPath(
      ApiEndpoints.blogRecent,
      fallbackIcon: Icons.article_rounded,
      fallbackRoute: '/blog-hub',
      badge: 'Yeni',
    );
    if (recent.isNotEmpty) return _dedupe(recent);
    return _fetchPath(
      ApiEndpoints.blog,
      fallbackIcon: Icons.menu_book_rounded,
      fallbackRoute: '/blog-hub',
    );
  }

  Future<List<NativeFeatureItem>> _fetchCelebrities() {
    return _fetchPath(
      ApiEndpoints.celebrities,
      fallbackIcon: Icons.star_rounded,
      fallbackRoute: '/celebrities-hub',
    );
  }

  Future<List<NativeFeatureItem>> _fetchFanClubs() {
    return _fetchPath(
      ApiEndpoints.fanClubs,
      fallbackIcon: Icons.favorite_rounded,
      fallbackRoute: '/fan-club-hub',
    );
  }

  Future<List<NativeFeatureItem>> _fetchPath(
    String path, {
    required IconData fallbackIcon,
    required String fallbackRoute,
    String? badge,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(path);
      final rows = _itemsFromBody(res.data);
      return rows
          .map(
            (json) => _mapItem(
              json,
              fallbackIcon: fallbackIcon,
              fallbackRoute: fallbackRoute,
              badge: badge,
            ),
          )
          .where((item) => item.title.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> _itemsFromBody(dynamic body) {
    if (body is List) return asJsonList(body);
    if (body is! Map) return const [];
    final map = asJsonMap(body);
    if (map['success'] == true && map['data'] != null) {
      return _itemsFromBody(map['data']);
    }
    for (final key in const [
      'items',
      'data',
      'results',
      'games',
      'rooms',
      'tournaments',
      'dreams',
      'symbols',
      'posts',
      'blogs',
      'celebrities',
      'fanClubs',
      'clubs',
    ]) {
      final raw = map[key];
      if (raw is List) return asJsonList(raw);
      if (raw is Map) {
        final nested = _itemsFromBody(raw);
        if (nested.isNotEmpty) return nested;
      }
    }
    if (map['id'] != null || map['slug'] != null || map['title'] != null) {
      return [map];
    }
    return const [];
  }

  NativeFeatureItem _mapItem(
    Map<String, dynamic> json, {
    required IconData fallbackIcon,
    required String fallbackRoute,
    String? badge,
  }) {
    final id =
        pick(json, ['id', '_id', 'slug', 'key'])?.toString() ??
        json.hashCode.toString();
    final title =
        jsonDisplayLabel(
          pick(json, [
            'title',
            'name',
            'label',
            'displayName',
            'question',
            'symbol',
          ]),
        ) ??
        'Canlifal';
    final subtitle =
        jsonDisplayLabel(
          pick(json, [
            'description',
            'summary',
            'excerpt',
            'subtitle',
            'category',
            'type',
            'meaning',
          ]),
          keys: const ['description', 'summary', 'excerpt', 'name', 'title'],
        ) ??
        _subtitleFor(json);
    final slug = pick(json, ['slug'])?.toString();
    final routeRaw = pick(json, ['route', 'path', 'url'])?.toString();
    final route = _safeRoute(routeRaw, fallbackRoute, slug);
    final image = pick(json, [
      'imageUrl',
      'image',
      'thumbnail',
      'thumbnailUrl',
      'coverUrl',
      'avatarUrl',
      'logoUrl',
    ])?.toString();
    final metric = _metricLabel(json);
    return NativeFeatureItem(
      id: id,
      title: title,
      subtitle: subtitle,
      route: route,
      icon: fallbackIcon,
      imageUrl: image != null && image.startsWith('http') ? image : null,
      metricLabel: metric,
      badge: badge ?? pick(json, ['badge', 'status', 'tag'])?.toString(),
    );
  }

  String _safeRoute(String? route, String fallback, String? slug) {
    final raw = route?.trim();
    if (raw != null && raw.startsWith('/') && raw.length < 80) return raw;
    if (fallback == '/blog-hub' && slug != null && slug.isNotEmpty) {
      return '/blog/$slug';
    }
    if (fallback == '/dreams-hub' && slug != null && slug.isNotEmpty) {
      return '/ruya/$slug';
    }
    return fallback;
  }

  String _subtitleFor(Map<String, dynamic> json) {
    final count = asInt(
      pick(json, [
        'memberCount',
        'followersCount',
        'viewCount',
        'playerCount',
        'entriesCount',
      ]),
    );
    if (count > 0) return '$count etkileşim';
    final createdAt = pick(json, ['createdAt', 'date'])?.toString();
    if (createdAt != null && createdAt.isNotEmpty) return createdAt;
    return 'Canlifal.com verisi';
  }

  String? _metricLabel(Map<String, dynamic> json) {
    final count = asInt(
      pick(json, [
        'memberCount',
        'followersCount',
        'viewCount',
        'playerCount',
        'commentCount',
      ]),
    );
    if (count <= 0) return null;
    return count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}K' : '$count';
  }

  List<NativeFeatureItem> _dedupe(List<NativeFeatureItem> items) {
    final seen = <String>{};
    final out = <NativeFeatureItem>[];
    for (final item in items) {
      final key = '${item.title}|${item.route}'.toLowerCase();
      if (seen.add(key)) out.add(item);
    }
    return out;
  }
}
