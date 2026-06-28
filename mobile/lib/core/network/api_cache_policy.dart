import 'package:dio/dio.dart';

/// GET istekleri için TTL ve cache kuralları.
abstract final class ApiCachePolicy {
  static const defaultTtl = Duration(seconds: 60);
  static const staleMaxAge = Duration(days: 7);

  /// Bu istek HTTP cache katmanından geçmez.
  static bool isCacheable(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return false;
    if (options.extra['noCache'] == true) return false;
    if (options.extra['forceRefresh'] == true) return false;

    final path = normalizedPath(options.path);
    if (path.isEmpty) return false;

    for (final blocked in _neverCacheFragments) {
      if (path.contains(blocked)) return false;
    }
    return true;
  }

  static Duration ttlFor(RequestOptions options) {
    final path = normalizedPath(options.path);

    for (final rule in _ttlRules) {
      if (rule.prefix.isNotEmpty && path.startsWith(rule.prefix)) {
        return rule.ttl;
      }
      if (rule.contains.isNotEmpty && path.contains(rule.contains)) {
        return rule.ttl;
      }
    }
    return defaultTtl;
  }

  static String normalizedPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) {
      return uri.path;
    }
    return path.startsWith('/') ? path : '/$path';
  }

  static const _neverCacheFragments = [
    '/api/auth/',
    '/auth/mobile-',
    '/auth/refresh',
    '/stream',
    '/sse',
    '/token',
    '/trtc',
    '/livekit',
    '/device-token',
    '/payment',
    '/stripe',
    '/webhook',
  ];

  static const _ttlRules = [
    _TtlRule(prefix: '/api/me', ttl: Duration(seconds: 45)),
    _TtlRule(prefix: '/api/messages', ttl: Duration(seconds: 30)),
    _TtlRule(prefix: '/api/notifications', ttl: Duration(minutes: 2)),
    _TtlRule(prefix: '/api/chat/rooms', ttl: Duration(seconds: 30)),
    _TtlRule(prefix: '/api/live', ttl: Duration(seconds: 15)),
    _TtlRule(prefix: '/api/video', ttl: Duration(seconds: 15)),
    _TtlRule(prefix: '/api/banners', ttl: Duration(minutes: 5)),
    _TtlRule(prefix: '/api/homepage', ttl: Duration(minutes: 5)),
    _TtlRule(prefix: '/api/advisors', ttl: Duration(minutes: 2)),
    _TtlRule(prefix: '/api/fortune-tellers', ttl: Duration(minutes: 2)),
    _TtlRule(prefix: '/api/users/me/stats', ttl: Duration(minutes: 2)),
    _TtlRule(prefix: '/api/users/me/activity', ttl: Duration(minutes: 2)),
    _TtlRule(prefix: '/api/wallet', ttl: Duration(seconds: 20)),
    _TtlRule(prefix: '/api/jeton', ttl: Duration(minutes: 3)),
    _TtlRule(prefix: '/api/social/posts', ttl: Duration(seconds: 45)),
    _TtlRule(prefix: '/api/social/stories', ttl: Duration(seconds: 45)),
    _TtlRule(contains: '/music-queue', ttl: Duration(seconds: 10)),
    _TtlRule(contains: '/presence', ttl: Duration(seconds: 8)),
  ];
}

class _TtlRule {
  const _TtlRule({
    this.prefix = '',
    this.contains = '',
    required this.ttl,
  });

  final String prefix;
  final String contains;
  final Duration ttl;
}
