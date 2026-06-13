import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bootstrap/app_startup_log.dart';
import '../../../../core/config/env.dart';
import '../../../../core/onesignal/onesignal_bootstrap.dart';
import '../../../../core/network/cookie_jar_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/loading_timeout.dart';
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
  static const _sessionTimeout = Duration(seconds: 10);
  static const _profileTimeout = Duration(seconds: 8);
  static const _bootTimeout = Duration(seconds: 12);
  static const _actionTimeout = Duration(seconds: 30);

  Timer? _bootWatchdog;

  Future<UserEntity?> _sessionUser() => LoadingTimeout.run(
        ref.read(authRepositoryProvider).currentUser(),
        timeout: _sessionTimeout,
        message: 'Oturum kontrolü zaman aşımına uğradı',
      );

  Future<UserEntity?> _withSiteProfile(UserEntity? base) async {
    if (base == null) return null;
    if (Env.useMobileAuth) return base;
    if (!Env.useNextAuth) return base;
    try {
      return await LoadingTimeout.run(
        ref.read(profileRemoteProvider).mySiteProfile(),
        timeout: _profileTimeout,
        message: 'Profil yüklenemedi',
      );
    } catch (_) {
      return base;
    }
  }

  Future<UserEntity?> _resolvedUser() async {
    try {
      final base = await _sessionUser();
      return await _withSiteProfile(base);
    } catch (_) {
      return null;
    }
  }

  void _cancelBootWatchdog() {
    _bootWatchdog?.cancel();
    _bootWatchdog = null;
  }

  @override
  Future<UserEntity?> build() async {
    AppStartupLog.authStart();
    _cancelBootWatchdog();
    _bootWatchdog = Timer(_bootTimeout + const Duration(seconds: 2), () {
      final current = state;
      if (current.isLoading && !current.hasValue) {
        AppStartupLog.authFinish(hasUser: false, error: true);
        state = const AsyncValue.data(null);
      }
    });
    ref.onDispose(_cancelBootWatchdog);

    try {
      final user = await LoadingTimeout.run(
        _resolvedUser(),
        timeout: _bootTimeout,
        message: 'Oturum kontrolü zaman aşımına uğradı',
      );
      AppStartupLog.authFinish(hasUser: user != null);
      return user;
    } catch (_) {
      AppStartupLog.authFinish(hasUser: false, error: true);
      return null;
    } finally {
      _cancelBootWatchdog();
    }
  }

  Future<void> login(String email, String password) async {
    await _runUserAction(() async {
      state = await AsyncValue.guard(() async {
        final u = await LoadingTimeout.run(
          ref.read(authRepositoryProvider).login(
                email: email,
                password: password,
              ),
          timeout: _actionTimeout,
          message: 'Giriş zaman aşımına uğradı',
        );
        return _withSiteProfile(u);
      });
      _clearGuestModeOnSuccess();
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
    await _runUserAction(() async {
      state = await AsyncValue.guard(() async {
        final u = await LoadingTimeout.run(
          ref.read(authRepositoryProvider).register(
                email: email,
                password: password,
                displayName: displayName,
                username: username,
                phone: phone,
                birthDate: birthDate,
                birthTime: birthTime,
                language: language,
              ),
          timeout: _actionTimeout,
          message: 'Kayıt zaman aşımına uğradı',
        );
        return _withSiteProfile(u);
      });
      _clearGuestModeOnSuccess();
    });
  }

  Future<void> loginWithGoogle() async {
    await _runUserAction(() async {
      state = await AsyncValue.guard(() async {
        final u = await LoadingTimeout.run(
          ref.read(authRepositoryProvider).loginWithGoogle(),
          timeout: _actionTimeout,
          message: 'Google girişi zaman aşımına uğradı',
        );
        return _withSiteProfile(u);
      });
      _clearGuestModeOnSuccess();
    });
  }

  Future<void> loginWithTikTok() async {
    await _runUserAction(() async {
      state = await AsyncValue.guard(() async {
        final u = await LoadingTimeout.run(
          ref.read(authRepositoryProvider).loginWithTikTok(),
          timeout: _actionTimeout,
          message: 'TikTok girişi zaman aşımına uğradı',
        );
        return _withSiteProfile(u);
      });
      _clearGuestModeOnSuccess();
    });
  }

  Future<void> logout() async {
    ref.read(authUserActionBusyProvider.notifier).state = false;
    ref.read(guestModeProvider.notifier).state = false;
    await OneSignalBootstrap.logout();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshMe() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => LoadingTimeout.run(
        _resolvedUser(),
        timeout: _bootTimeout,
        message: 'Oturum yenilenemedi',
      ),
    );
  }

  /// Tam ekran loading dialog yok — yalnızca buton içi spinner.
  Future<void> _runUserAction(Future<void> Function() action) async {
    ref.read(authUserActionBusyProvider.notifier).state = true;
    try {
      await action();
    } finally {
      ref.read(authUserActionBusyProvider.notifier).state = false;
    }
  }

  void _clearGuestModeOnSuccess() {
    if (state.valueOrNull != null) {
      ref.read(guestModeProvider.notifier).state = false;
    }
  }
}

/// Misafir gezinme — oturum açmadan keşfet / feed (sınırlı).
final guestModeProvider = StateProvider<bool>((ref) => false);

/// Kullanıcı tetiklemeli giriş/kayıt — arka plan oturum kontrolünden ayrı.
final authUserActionBusyProvider = StateProvider<bool>((ref) => false);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserEntity?>(AuthController.new);
