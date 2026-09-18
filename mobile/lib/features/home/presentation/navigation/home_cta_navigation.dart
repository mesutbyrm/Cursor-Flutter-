import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/canlifal_motion_tokens.dart';

/// Ana sayfa CTA geçişleri — referans §33-A.
///
/// Hedef route'ların `app_router` içinde `AppPageTransitions.fadeSlide` /
/// `sharedAxis` kullanması tercih edilir; burada tek giriş noktası.
enum HomeCtaDestination {
  live,
  voiceRooms,
  discover,
  gold,
  profile,
  generic,
}

HomeCtaDestination homeCtaDestinationForRoute(String route) {
  final r = route.trim().toLowerCase();
  if (r.startsWith('/live')) return HomeCtaDestination.live;
  if (r.contains('voice')) return HomeCtaDestination.voiceRooms;
  if (r.contains('tanis') || r.contains('social')) {
    return HomeCtaDestination.discover;
  }
  if (r.contains('premium') || r.contains('gold')) {
    return HomeCtaDestination.gold;
  }
  if (r.startsWith('/profile')) return HomeCtaDestination.profile;
  return HomeCtaDestination.generic;
}

Duration homeCtaTransitionDuration(String route) {
  switch (homeCtaDestinationForRoute(route)) {
    case HomeCtaDestination.live:
    case HomeCtaDestination.voiceRooms:
      return CanlifalMotionTokens.page;
    case HomeCtaDestination.discover:
    case HomeCtaDestination.gold:
      return const Duration(milliseconds: 380);
    case HomeCtaDestination.profile:
    case HomeCtaDestination.generic:
      return CanlifalMotionTokens.page;
  }
}

void pushFromHomeCta(BuildContext context, String location) {
  final path = location.trim();
  if (path.isEmpty) return;
  context.push(path);
}
