import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import 'auth_route_paths.dart';

/// go_router redirect — tek kaynak.
abstract final class AuthRedirect {
  /// E-posta / OTP derin linkleri — go_router sayfası; builder gateway değil.
  static bool isDeepLinkAuthPath(String path) =>
      path.startsWith('/auth/reset-password') || path == '/auth/otp-verify';

  static String? targetFor({
    required String path,
    required String matchedLocation,
    required UserEntity? user,
    required bool guest,
  }) {
    if (path == '/splash') {
      return '/feed';
    }

    final authed = user != null;
    final legacyAuthEntry =
        matchedLocation == '/login' ||
        matchedLocation == '/register' ||
        matchedLocation.startsWith('/auth/forgot-password');
    final canlifalWeb = matchedLocation == '/canlifal-web';

    // Misafir — keşfet / feed.
    if (!authed && guest && legacyAuthEntry) {
      return '/feed';
    }

    // Oturumsuz: giriş UI MaterialApp.builder'da (route geçişi / barrier yok).
    if (!authed && !guest) {
      if (canlifalWeb || isDeepLinkAuthPath(matchedLocation)) return null;
      if (legacyAuthEntry || matchedLocation == '/feed') return null;
      return '/feed';
    }
    if (authed && (legacyAuthEntry || isDeepLinkAuthPath(matchedLocation))) {
      return '/feed';
    }
    return null;
  }

  static bool wouldChangeLocation({
    required String path,
    required String matchedLocation,
    required AsyncValue<UserEntity?> auth,
    required bool guest,
  }) {
    if (auth.isLoading) return false;
    final target = targetFor(
      path: path,
      matchedLocation: matchedLocation,
      user: auth.valueOrNull,
      guest: guest,
    );
    if (target == null) return false;
    return target != matchedLocation;
  }

  static bool isPublicAuthPath(String path) =>
      AuthRoutePaths.isPublicAuthPath(path);
}
