import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'auth_route_paths.dart';

/// go_router redirect — tek kaynak; [RouterRefresh] yalnızca hedef değişince tetiklenir.
abstract final class AuthRedirect {
  static String? targetFor({
    required String path,
    required String matchedLocation,
    required UserEntity? user,
    required bool guest,
  }) {
    if (path == '/splash') {
      return user != null ? '/feed' : '/login';
    }

    final authed = user != null;
    final publicAuthPages =
        matchedLocation == '/login' ||
        matchedLocation == '/register' ||
        matchedLocation.startsWith('/auth/forgot-password') ||
        matchedLocation.startsWith('/auth/reset-password') ||
        matchedLocation == '/auth/otp-verify';
    final canlifalWeb = matchedLocation == '/canlifal-web';

    if (!authed && !guest && !publicAuthPages && !canlifalWeb) {
      return '/login';
    }
    if (authed && publicAuthPages) return '/feed';
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
