import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/onesignal/onesignal_bootstrap.dart';
import '../../../../core/network/cookie_jar_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/native_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final nativeAuthDataSourceProvider = Provider<NativeAuthDataSource>((ref) {
  return NativeAuthDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(nativeAuthDataSourceProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(cookieJarProvider),
  );
});

class AuthController extends AsyncNotifier<UserEntity?> {
  Future<UserEntity?> _sessionUser() =>
      ref.read(authRepositoryProvider).currentUser();

  Future<UserEntity?> _withSiteProfile(UserEntity? base) async {
    if (base == null) return null;
    if (Env.useMobileAuth) return base;
    if (!Env.useNextAuth) return base;
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

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String username,
    String? phone,
    String? birthDate,
    String? birthTime,
    String language = 'tr',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final u = await ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            displayName: displayName,
            username: username,
            phone: phone,
            birthDate: birthDate,
            birthTime: birthTime,
            language: language,
          );
      return _withSiteProfile(u);
    });
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final u = await ref.read(authRepositoryProvider).loginWithGoogle();
      return _withSiteProfile(u);
    });
  }

  Future<void> loginWithTikTok() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final u = await ref.read(authRepositoryProvider).loginWithTikTok();
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
