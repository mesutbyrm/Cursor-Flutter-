import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/user_theme_sync_provider.dart';

import '../../../../core/bootstrap/user_session_cleanup.dart';
import '../../../../core/bootstrap/session_data_refresh.dart';
import '../../../../core/bootstrap/app_startup_log.dart';
import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../core/config/env.dart';
import '../../../../core/network/api_http_cache.dart';
import '../../../../core/offline/api_cache_store.dart';
import '../../../../core/onesignal/onesignal_bootstrap.dart';
import '../../../../core/push/push_delivery.dart';
import '../../../../core/network/cookie_jar_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/loading_timeout.dart';
import '../../../../core/performance/network_perf.dart';
import '../../../../core/auth/saved_accounts_store.dart';
import '../../../../core/auth/session_user_cache.dart';
import '../../../../core/network/token_storage.dart';
import '../../../fortune/data/fortune_birth_profile_store.dart';
import '../../../fortune/presentation/providers/fortune_birth_profile_provider.dart';
import '../../../profile/presentation/providers/profile_hub_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../voice_hub/presentation/utils/voice_room_stale_session_guard.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/navigation/post_login_navigation.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/native_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/active_session_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../trtc/presentation/trtc_bootstrap_service.dart';
import 'auth_service_provider.dart';
import '../../../../core/network/auth_token_refresh_coordinator.dart';
import '../../../../core/auth/refresh_me_gate.dart';

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
    ref.watch(authServiceProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(cookieJarProvider),
    ref.watch(sessionUserCacheProvider),
  );
});

class AuthController extends AsyncNotifier<UserEntity?> {
  static const _sessionTimeout = StartupPerf.authBootTimeout;
  static const _profileTimeout = Duration(seconds: 2);
  static const _bootTimeout = StartupPerf.authBootTimeout;
  static const _actionTimeout = Duration(seconds: 30);

  Timer? _bootWatchdog;
  var _sessionEpoch = 0;
  final _refreshMeGate = RefreshMeGate();

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

  Future<UserEntity?> _resolvedUser({bool includeSiteProfile = true}) async {
    try {
      if (!includeSiteProfile || Env.useMobileAuth || !Env.useNextAuth) {
        return await _sessionUser();
      }
      final pair = await NetworkPerf.parallel<Object?>([
        _sessionUser(),
        () async {
          try {
            return await LoadingTimeout.run(
              ref.read(profileRemoteProvider).mySiteProfile(),
              timeout: _profileTimeout,
              message: 'Profil yüklenemedi',
            );
          } catch (_) {
            return null;
          }
        }(),
      ]);
      final base = pair[0];
      if (base == null) return null;
      return (pair[1] as UserEntity?) ?? base as UserEntity;
    } catch (_) {
      return null;
    }
  }

  /// Açılış sonrası profil birleştirme + push kaydı — kritik yolu bloklamaz.
  Future<void> _enrichUserAfterBoot(UserEntity base) async {
    unawaited(clearStaleVoicePresenceOnAuth(ref));
    try {
      final enriched = await _withSiteProfile(base);
      if (enriched != null && state.valueOrNull?.id == enriched.id) {
        state = AsyncValue.data(enriched);
        await ref.read(sessionUserCacheProvider).write(enriched);
      }
    } catch (_) {}

    final id = base.id;
    if (id.isNotEmpty) {
      if (PushDelivery.usesOneSignal) {
        unawaited(OneSignalBootstrap.login(id));
      }
      unawaited(ref.read(userThemeSyncProvider).pullFromServer());
    }
  }

  /// Önbellekten hızlı açılış sonrası oturumu arka planda doğrula.
  Future<void> _validateSessionInBackground(
    String token,
    SessionUserCache sessionCache,
    int epoch,
  ) async {
    try {
      final user = await LoadingTimeout.run(
        _sessionUser(),
        timeout: _bootTimeout,
        message: 'Oturum kontrolü zaman aşımına uğradı',
      );
      if (epoch != _sessionEpoch) return;
      if (user != null) {
        await sessionCache.write(user);
        if (state.valueOrNull?.id == user.id) {
          state = AsyncValue.data(user);
        }
        unawaited(_enrichUserAfterBoot(user));
      }
    } catch (_) {}
  }

  void _cancelBootWatchdog() {
    _bootWatchdog?.cancel();
    _bootWatchdog = null;
  }

  @override
  Future<UserEntity?> build() async {
    AuthTokenRefreshCoordinator.instance.onSessionExpired = () {
      unawaited(logout());
    };
    ref.onDispose(() {
      if (AuthTokenRefreshCoordinator.instance.onSessionExpired != null) {
        AuthTokenRefreshCoordinator.instance.onSessionExpired = null;
      }
    });

    AppStartupLog.authStart();
    _cancelBootWatchdog();

    final tokenStorage = ref.read(tokenStorageProvider);
    final sessionCache = ref.read(sessionUserCacheProvider);
    final tokenFuture = tokenStorage.readAccess();
    final cacheFuture = sessionCache.read();
    final token = await tokenFuture;
    final hasToken = token != null &&
        token.isNotEmpty &&
        token != TokenStorage.sessionCookieMarker;

    if (hasToken) {
      final cached = await cacheFuture;
      if (cached != null) {
        AppStartupLog.authFinish(hasUser: true);
        unawaited(_enrichUserAfterBoot(cached));
        final epoch = _sessionEpoch;
        unawaited(_validateSessionInBackground(token, sessionCache, epoch));
        return cached;
      }
    }

    _bootWatchdog = Timer(_bootTimeout + const Duration(milliseconds: 200), () async {
      final current = state;
      if (!current.isLoading || current.hasValue) return;
      if (hasToken) {
        final cached = await sessionCache.read();
        if (cached != null) {
          AppStartupLog.authFinish(hasUser: true);
          state = AsyncValue.data(cached);
          unawaited(_enrichUserAfterBoot(cached));
        }
        return;
      }
      AppStartupLog.authFinish(hasUser: false, error: true);
      state = const AsyncValue.data(null);
    });
    ref.onDispose(_cancelBootWatchdog);

    try {
      final user = await LoadingTimeout.run(
        _sessionUser(),
        timeout: _bootTimeout,
        message: 'Oturum kontrolü zaman aşımına uğradı',
      );
      AppStartupLog.authFinish(hasUser: user != null);
      if (user != null) {
        await sessionCache.write(user);
        unawaited(_enrichUserAfterBoot(user));
        unawaited(TrtcBootstrapService.prewarmAfterAuth());
      }
      return user;
    } catch (_) {
      if (hasToken) {
        final cached = await sessionCache.read();
        if (cached != null) {
          AppStartupLog.authFinish(hasUser: true);
          unawaited(_enrichUserAfterBoot(cached));
          return cached;
        }
      }
      AppStartupLog.authFinish(hasUser: false, error: true);
      return null;
    } finally {
      _cancelBootWatchdog();
    }
  }

  Future<void> _afterAuthSuccess(
    UserEntity? user, {
    String? previousUserId,
  }) async {
    if (user == null || user.id.isEmpty) return;
    final prevId = previousUserId?.trim();
    if (prevId != null &&
        prevId.isNotEmpty &&
        prevId != user.id) {
      await teardownRealtimeOnLogout(ref, userId: prevId);
    }
    _sessionEpoch++;
    AuthTokenRefreshCoordinator.instance.markSessionFresh(
      grace: const Duration(seconds: 90),
    );
    await ref.read(sessionUserCacheProvider).write(user);
    unawaited(
      ref.read(savedAccountsStoreProvider).upsertFromSession(
            user: user,
            tokens: ref.read(tokenStorageProvider),
          ),
    );
    invalidateAuthenticatedShellData(ref, skipPresenceHeartbeat: true);
    unawaited(clearStaleVoicePresenceOnAuth(ref));
    if (PushDelivery.usesOneSignal) {
      unawaited(OneSignalBootstrap.login(user.id));
    }
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () {
        unawaited(TrtcBootstrapService.prewarmAfterAuth());
      }),
    );
    unawaited(_seedFortuneBirthFromProfile(user.id));

    final pending = PostLoginNavigation.takePending();
    if (pending != null) {
      final router = ref.read(goRouterProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          router.push(pending);
        } catch (_) {
          router.go('/feed');
        }
      });
    }
  }

  Future<void> _seedFortuneBirthFromProfile(String userId) async {
    try {
      final ext = await ref.read(profileExtendedProvider.future);
      final date = ext.birthDate;
      if (date == null) return;
      final store = await ref.read(fortuneBirthProfileStoreProvider.future);
      if (store.read(userId) != null) return;
      TimeOfDay time = const TimeOfDay(hour: 12, minute: 0);
      final raw = ext.birthTime;
      if (raw != null && raw.contains(':')) {
        final parts = raw.split(':');
        if (parts.length >= 2) {
          time = TimeOfDay(
            hour: (int.tryParse(parts[0]) ?? 12).clamp(0, 23),
            minute: (int.tryParse(parts[1]) ?? 0).clamp(0, 59),
          );
        }
      }
      await store.save(
        userId,
        FortuneBirthProfile(birthDate: date, birthTime: time),
      );
      ref.invalidate(fortuneBirthProfileProvider);
    } catch (_) {}
  }

  Future<void> login(String identifier, String password) async {
    await _runUserAction(() async {
      final previousUserId = ref.read(authControllerProvider).valueOrNull?.id;
      state = await AsyncValue.guard(() async {
        final u = await LoadingTimeout.run(
          ref.read(authRepositoryProvider).login(
                identifier: identifier,
                password: password,
              ),
          timeout: _actionTimeout,
          message: 'Giriş zaman aşımına uğradı',
        );
        final resolved = await _withSiteProfile(u);
        await _afterAuthSuccess(
          resolved,
          previousUserId: previousUserId,
        );
        return resolved;
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
        final resolved = await _withSiteProfile(u);
        await _afterAuthSuccess(resolved);
        // Web kaydı hoş geldin/doğrulama e-postası gönderir; `mobile-register`
        // göndermez — mobil kayıtta da doğrulama e-postasını biz tetikleriz.
        unawaited(_sendVerificationMailBestEffort());
        if (birthDate != null &&
            birthTime != null &&
            birthDate.isNotEmpty &&
            birthTime.isNotEmpty &&
            resolved != null) {
          final date = DateTime.tryParse(birthDate);
          if (date != null) {
            final parts = birthTime.split(':');
            final time = TimeOfDay(
              hour: parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 12) : 12,
              minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
            );
            final store =
                await ref.read(fortuneBirthProfileStoreProvider.future);
            await store.save(
              resolved.id,
              FortuneBirthProfile(birthDate: date, birthTime: time),
            );
            ref.invalidate(fortuneBirthProfileProvider);
          }
        }
        return resolved;
      });
      _clearGuestModeOnSuccess();
    });
  }

  Future<void> _sendVerificationMailBestEffort() async {
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
    } catch (_) {}
  }

  Future<void> loginWithGoogle() async {
    await _runUserAction(() async {
      state = await AsyncValue.guard(() async {
        final u = await LoadingTimeout.run(
          ref.read(authRepositoryProvider).loginWithGoogle(),
          timeout: _actionTimeout,
          message: 'Google girişi zaman aşımına uğradı',
        );
        final resolved = await _withSiteProfile(u);
        await _afterAuthSuccess(resolved);
        return resolved;
      });
      _clearGuestModeOnSuccess();
    });
  }

  Future<void> loginWithApple({String? referralCode}) async {
    await _runUserAction(() async {
      state = await AsyncValue.guard(() async {
        final u = await LoadingTimeout.run(
          ref.read(authRepositoryProvider).loginWithApple(
                referralCode: referralCode,
              ),
          timeout: _actionTimeout,
          message: 'Apple girişi zaman aşımına uğradı',
        );
        final resolved = await _withSiteProfile(u);
        await _afterAuthSuccess(resolved);
        return resolved;
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
        final resolved = await _withSiteProfile(u);
        await _afterAuthSuccess(resolved);
        return resolved;
      });
      _clearGuestModeOnSuccess();
    });
  }

  /// Kayıtlı hesaba geç — mevcut oturumun token'ları saklanır. Hedef hesabın
  /// oturumu artık geçersizse önceki hesap geri yüklenir ve hedef listeden
  /// çıkarılır (ekranda bir hesap, istekte başka hesabın token'ı kalmaz).
  Future<void> switchToSavedAccount(String userId) async {
    await _runUserAction(() async {
      final store = ref.read(savedAccountsStoreProvider);
      final target = await store.byUserId(userId);
      if (target == null) {
        throw const ApiException('Hesap bulunamadı');
      }
      final current = state.valueOrNull;
      if (current?.id == target.userId) return;
      final tokens = ref.read(tokenStorageProvider);
      if (current != null) {
        await store.upsertFromSession(user: current, tokens: tokens);
      }
      final restore =
          current == null ? null : await store.byUserId(current.id);

      final user = await _activateSavedTokens(target);
      if (user == null) {
        await store.remove(target.userId);
        await _restoreTokens(restore);
        ref.invalidate(savedAccountsListProvider);
        throw ApiException(
          '${target.label} hesabının oturumu sona ermiş. '
          'Hesabı yeniden ekleyin.',
        );
      }
      state = AsyncValue.data(user);
      await _afterAuthSuccess(user, previousUserId: current?.id);
      ref.invalidate(savedAccountsListProvider);
    });
  }

  /// Yeni hesap ekle — mevcut hesap saklanır; giriş başarısız olursa aktif
  /// oturum değişmez. Aktif hesap dahil en fazla [maxSavedAccounts] hesap.
  Future<void> addAccountWithPassword(String identifier, String password) =>
      _addAccount(
        () => ref.read(authRepositoryProvider).login(
              identifier: identifier,
              password: password,
            ),
        timeoutMessage: 'Giriş zaman aşımına uğradı',
      );

  Future<void> addAccountWithGoogle() => _addAccount(
        () => ref.read(authRepositoryProvider).loginWithGoogle(),
        timeoutMessage: 'Google girişi zaman aşımına uğradı',
      );

  Future<void> addAccountWithApple() => _addAccount(
        () => ref.read(authRepositoryProvider).loginWithApple(),
        timeoutMessage: 'Apple girişi zaman aşımına uğradı',
      );

  Future<void> _addAccount(
    Future<UserEntity> Function() signIn, {
    required String timeoutMessage,
  }) async {
    await _runUserAction(() async {
      final store = ref.read(savedAccountsStoreProvider);
      final tokens = ref.read(tokenStorageProvider);
      final current = state.valueOrNull;
      if (current != null) {
        await store.upsertFromSession(user: current, tokens: tokens);
      }
      if (!await store.canAddAnother()) {
        throw const ApiException(
          'En fazla $maxSavedAccounts hesap ekleyebilirsiniz. '
          'Yeni hesap için önce bir hesabı kaldırın.',
        );
      }
      final restore =
          current == null ? null : await store.byUserId(current.id);

      UserEntity? user;
      try {
        final u = await LoadingTimeout.run(
          signIn(),
          timeout: _actionTimeout,
          message: timeoutMessage,
        );
        user = await _withSiteProfile(u);
      } catch (_) {
        // Başarısız girişte token yazılmaz; yine de önceki oturumu garanti et.
        await _restoreTokens(restore);
        rethrow;
      }
      if (user == null) {
        await _restoreTokens(restore);
        throw const ApiException('Giriş tamamlanamadı');
      }
      state = AsyncValue.data(user);
      await _afterAuthSuccess(user, previousUserId: current?.id);
      ref.invalidate(savedAccountsListProvider);
      _clearGuestModeOnSuccess();
    });
  }

  /// Kayıtlı token'ları etkinleştirir ve oturumun gerçekten o hesaba ait
  /// olduğunu doğrular. Geçersizse null döner; [state]'e dokunmaz.
  Future<UserEntity?> _activateSavedTokens(SavedAccountEntry target) async {
    final tokens = ref.read(tokenStorageProvider);
    await tokens.writeTokens(
      access: target.accessToken,
      refresh: target.refreshToken,
      userId: target.userId,
    );
    // Süresi dolmuş access token yenilenirken genel "oturum bitti" çıkışı
    // tetiklenmesin; sonuç burada doğrulanır.
    AuthTokenRefreshCoordinator.instance.markSessionFresh(
      grace: const Duration(seconds: 90),
    );
    try {
      final user = await LoadingTimeout.run(
        _resolvedUser(),
        timeout: _actionTimeout,
        message: 'Hesap doğrulanamadı',
      );
      if (user == null || user.id != target.userId) return null;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> _restoreTokens(SavedAccountEntry? entry) async {
    final tokens = ref.read(tokenStorageProvider);
    if (entry == null) {
      await tokens.clear();
      return;
    }
    await tokens.writeTokens(
      access: entry.accessToken,
      refresh: entry.refreshToken,
      userId: entry.userId,
    );
  }

  /// Çıkış sonrası sıradaki kayıtlı hesaba geçer; geçersiz olanları atlar.
  Future<void> _resumeNextSavedAccount() async {
    final store = ref.read(savedAccountsStoreProvider);
    for (final next in await store.readAll()) {
      final user = await _activateSavedTokens(next);
      if (user != null) {
        state = AsyncValue.data(user);
        await _afterAuthSuccess(user);
        ref.invalidate(savedAccountsListProvider);
        return;
      }
      await store.remove(next.userId);
    }
    await ref.read(tokenStorageProvider).clear();
    ref.invalidate(savedAccountsListProvider);
  }

  /// Bu hesabın tüm cihazlardaki oturumlarını kapatır ve yerel durumu da
  /// temizler. Diğer kayıtlı hesaplar etkilenmez; varsa sıradakine geçilir.
  Future<void> logoutAllDevices() async {
    await ref.read(authRemoteDataSourceProvider).logoutAllDevices();
    await logout(switchToNextSaved: true);
  }

  /// Çıkış. Çıkılan hesap kayıtlı hesaplardan kaldırılır (token'ları sunucuda
  /// iptal edilir). [switchToNextSaved] true ise — kullanıcının kendi çıkışı —
  /// varsa sıradaki kayıtlı hesaba geçilir; oturum süresi dolduğunda geçilmez.
  Future<void> logout({bool switchToNextSaved = false}) async {
    ref.read(authUserActionBusyProvider.notifier).state = false;
    ref.read(guestModeProvider.notifier).state = false;
    _sessionEpoch++;
    AuthTokenRefreshCoordinator.instance.reset();
    final userId = state.valueOrNull?.id;
    if (PushDelivery.usesOneSignal) {
      await OneSignalBootstrap.logout();
    }
    await NetworkPerf.parallel([
      ApiHttpCache.clearAll(),
      ApiCacheStore.clearAll(),
    ]);
    await ref.read(sessionUserCacheProvider).clear();
    await teardownRealtimeOnLogout(ref, userId: userId);
    await ref.read(authRepositoryProvider).logout();
    if (userId != null) {
      await ref.read(savedAccountsStoreProvider).remove(userId);
      ref.invalidate(savedAccountsListProvider);
    }
    state = const AsyncValue.data(null);
    if (switchToNextSaved) {
      await _resumeNextSavedAccount();
    }
  }

  Future<void> refreshMe({bool force = false}) async {
    await _refreshMeGate.run(() => _refreshMeBody(), force: force);
  }

  Future<void> _refreshMeBody() async {
    final previous = state.valueOrNull;
    state = previous != null
        ? AsyncValue<UserEntity?>.loading().copyWithPrevious(
            AsyncValue.data(previous),
          )
        : const AsyncValue.loading();
    try {
      final user = await LoadingTimeout.run(
        _resolvedUser(),
        timeout: _bootTimeout,
        message: 'Oturum yenilenemedi',
      );
      state = AsyncValue.data(user ?? previous);
      if (user != null) {
        unawaited(_enrichUserAfterBoot(user));
      }
    } catch (e, st) {
      if (previous != null) {
        state = AsyncValue.data(previous);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
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

final activeSessionsProvider =
    FutureProvider.autoDispose<List<ActiveSessionEntity>>((ref) async {
  return ref.read(authRepositoryProvider).fetchActiveSessions();
});
