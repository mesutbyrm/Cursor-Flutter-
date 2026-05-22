import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/onesignal/onesignal_bootstrap.dart';
import '../../../../core/network/cookie_jar_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(cookieJarProvider),
  );
});

class AuthController extends AsyncNotifier<UserEntity?> {
  Future<UserEntity?> _sessionUser() =>
      ref.read(authRepositoryProvider).currentUser();

  Future<UserEntity?> _withSiteProfile(UserEntity? base) async {
    if (base == null || !Env.useNextAuth) return base;
    try {
      return await ref.read(profileRemoteProvider).mySiteProfile();
    } catch (_) {
      return base;
    }
  }

  Future<UserEntity?> _resolvedUser() async {
    final base = await _sessionUser();
    return _withSiteProfile(base);
  }

  @override
  Future<UserEntity?> build() async => _resolvedUser();

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final u = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      return _withSiteProfile(u);
    });
  }

  Future<void> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final u = await ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            displayName: displayName,
          );
      return _withSiteProfile(u);
    });
  }

  Future<void> logout() async {
    await OneSignalBootstrap.logout();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshMe() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_resolvedUser);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserEntity?>(AuthController.new);
