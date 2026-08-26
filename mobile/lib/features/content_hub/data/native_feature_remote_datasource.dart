import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/html_plain_text.dart';
import '../../../core/util/json_util.dart';
import '../domain/native_feature_item.dart';

Never _throwLast(Object error) {
  if (error is ApiException) throw error;
  throw ApiException(ApiException.userMessage(error));
}

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

  Future<NativeFeatureItem?> fetchDetail(
    NativeFeatureHubKind kind,
    String id,
  ) async {
    final key = id.trim();
    if (key.isEmpty) return null;
    return switch (kind) {
      NativeFeatureHubKind.blog => _fetchOne(
        ApiEndpoints.blogPost(key),
        fallbackIcon: Icons.article_rounded,
        fallbackRoute: '/blog/$key',
      ),
      NativeFeatureHubKind.celebrities => _fetchOne(
        ApiEndpoints.celebrity(key),
        fallbackIcon: Icons.star_rounded,
        fallbackRoute: '/celebrities/$key',
      ),
      NativeFeatureHubKind.fanClub => _fetchFanClub(key),
      NativeFeatureHubKind.dreams => _fetchDreamDetail(key),
      _ => null,
    };
  }

  Future<List<NativeFeatureItem>> fetchRelated(
    NativeFeatureHubKind kind,
    String id,
  ) async {
    final key = id.trim();
    if (key.isEmpty) return const [];
    return switch (kind) {
      NativeFeatureHubKind.celebrities => _fetchPath(
        ApiEndpoints.celebrityPosts(key),
        fallbackIcon: Icons.article_outlined,
        fallbackRoute: '/social',
      ),
      NativeFeatureHubKind.fanClub => _fetchPath(
        ApiEndpoints.fanClubPosts(key),
        fallbackIcon: Icons.forum_outlined,
        fallbackRoute: '/social',
      ),
      _ => Future.value(const <NativeFeatureItem>[]),
    };
  }

  Future<NativeFeatureItem?> _fetchDreamDetail(String id) async {
    final items = await _fetchDreams();
    for (final item in items) {
      if (item.id == id || item.route.endsWith('/$id')) return item;
    }
    return NativeFeatureItem(
      id: id,
      title: 'Rüya',
      subtitle: 'Rüya yorumu',
      route: '/dreams/$id',
      icon: Icons.nights_stay_rounded,
    );
  }

  Future<NativeFeatureItem?> _fetchFanClub(String id) async {
    final clubs = await _fetchFanClubs();
    for (final c in clubs) {
      if (c.id == id || c.route.endsWith('/$id')) return c;
    }
    return NativeFeatureItem(
      id: id,
      title: 'Fan kulübü',
      subtitle: 'Kulüp detayı',
      route: '/fan-club/$id',
      icon: Icons.favorite_rounded,
    );
  }

  Future<NativeFeatureItem?> _fetchOne(
    String path, {
    required IconData fallbackIcon,
    required String fallbackRoute,
  }) async {
    final items = await _fetchPath(
      path,
      fallbackIcon: fallbackIcon,
      fallbackRoute: fallbackRoute,
    );
    return items.isEmpty ? null : items.first;
  }

  Future<List<NativeFeatureItem>> _fetchGames() async {
    Object? lastError;
    final items = <NativeFeatureItem>[];
    for (final call in [
      () => _fetchPath(
        ApiEndpoints.homeGames,
        fallbackIcon: Icons.sports_esports_rounded,
        fallbackRoute: '/games-hub',
      ),
      () => _fetchPath(
        ApiEndpoints.tournaments,
        fallbackIcon: Icons.emoji_events_rounded,
        fallbackRoute: '/games-hub',
        badge: 'Turnuva',
      ),
    ]) {
      try {
        items.addAll(await call());
      } catch (e) {
        lastError = e;
      }
    }
    if (items.isEmpty && lastError != null) _throwLast(lastError);
    return _dedupe(items);
  }

  Future<List<NativeFeatureItem>> _fetchDreams() async {
    Object? lastError;
    final items = <NativeFeatureItem>[];
    for (final call in [
      () => _fetchPath(
        ApiEndpoints.dreams,
        fallbackIcon: Icons.nights_stay_rounded,
        fallbackRoute: '/dreams-hub',
      ),
      () => _fetchPath(
        ApiEndpoints.dreamSymbols,
        fallbackIcon: Icons.auto_stories_rounded,
        fallbackRoute: '/dreams-hub',
        badge: 'Sözlük',
      ),
      () => _fetchPath(
        ApiEndpoints.dreamContest,
        fallbackIcon: Icons.how_to_vote_rounded,
        fallbackRoute: '/dreams-hub',
        badge: 'Yarışma',
      ),
    ]) {
      try {
        items.addAll(await call());
      } catch (e) {
        lastError = e;
      }
    }
    if (items.isEmpty && lastError != null) _throwLast(lastError);
    return _dedupe(items);
  }

  Future<List<NativeFeatureItem>> _fetchBlog() async {
    Object? lastError;
    try {
      final recent = await _fetchPath(
        ApiEndpoints.blogRecent,
        fallbackIcon: Icons.article_rounded,
        fallbackRoute: '/blog-hub',
        badge: 'Yeni',
      );
      if (recent.isNotEmpty) return _dedupe(recent);
    } catch (e) {
      lastError = e;
    }
    try {
      return await _fetchPath(
        ApiEndpoints.blog,
        fallbackIcon: Icons.menu_book_rounded,
        fallbackRoute: '/blog-hub',
      );
    } catch (e) {
      lastError = e;
    }
    if (lastError != null) _throwLast(lastError);
    return const [];
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
    final titleRaw =
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
    final title = _plainOrFallback(titleRaw, 'Canlifal');
    final subtitleRaw =
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
    final subtitle = _plainOrFallback(subtitleRaw, 'Canlifal.com verisi');
    final slug = pick(json, ['slug'])?.toString();
    final routeRaw = pick(json, ['route', 'path', 'url'])?.toString();
    final route = nativeFeatureSafeRoute(
      routeRaw: routeRaw,
      fallbackRoute: fallbackRoute,
      slug: slug,
      id: id,
    );
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
    final bodyRaw = pick(json, [
      'content',
      'body',
      'html',
      'contentHtml',
      'text',
    ])?.toString();
    final body = bodyRaw == null || bodyRaw.trim().isEmpty
        ? null
        : htmlToPlainText(bodyRaw);
    return NativeFeatureItem(
      id: id,
      title: title,
      subtitle: subtitle,
      route: route,
      icon: fallbackIcon,
      imageUrl: image != null && image.startsWith('http') ? image : null,
      metricLabel: metric,
      badge: badge ?? pick(json, ['badge', 'status', 'tag'])?.toString(),
      body: body != null && body.isNotEmpty && body != subtitle ? body : null,
    );
  }

  String _plainOrFallback(String raw, String fallback) {
    final plain = htmlToPlainText(raw);
    return plain.isEmpty ? fallback : plain;
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

/// Hub kartı tıklama yolu — kendi hub'ına dönmez.
String nativeFeatureSafeRoute({
  required String? routeRaw,
  required String fallbackRoute,
  String? slug,
  required String id,
}) {
  final raw = routeRaw?.trim();
  if (raw != null &&
      raw.startsWith('/') &&
      raw.length < 80 &&
      raw != fallbackRoute) {
    return raw;
  }
  final key = (slug != null && slug.isNotEmpty) ? slug : id;
  if (fallbackRoute == '/blog-hub' && key.isNotEmpty) {
    return '/blog/$key';
  }
  if (fallbackRoute == '/celebrities-hub' && key.isNotEmpty) {
    return '/celebrities/$key';
  }
  if (fallbackRoute == '/fan-club-hub' && key.isNotEmpty) {
    return '/fan-club/$key';
  }
  if (fallbackRoute == '/dreams-hub' && key.isNotEmpty) {
    return '/dreams/$key';
  }
  return fallbackRoute;
}
