import 'social_discovery_user.dart';

/// `GET /api/social/discovery` sayfalı sonuç.
class SocialDiscoveryFeed {
  const SocialDiscoveryFeed({
    required this.users,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<SocialDiscoveryUser> users;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
}

/// `POST /api/social/actions` sonucu.
class SocialDiscoveryActionResult {
  const SocialDiscoveryActionResult({
    required this.success,
    this.toggled = false,
    this.matched = false,
    this.message,
    this.errorCode,
  });

  final bool success;
  final bool toggled;
  final bool matched;
  final String? message;
  final String? errorCode;
}
