import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/cache_service.dart';
import '../../core/storage/secure_token_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/social_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../data/services/live_rtc_service.dart';
import '../../data/services/realtime_client.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/social_repository.dart';

final appConfigProvider = Provider<AppConfig>((Ref ref) {
  return AppConfig.fromEnvironment();
});

final tokenStorageProvider = Provider<SecureTokenStorage>((Ref ref) {
  return SecureTokenStorage();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((Ref ref) {
  return SharedPreferences.getInstance();
});

final cacheServiceProvider = FutureProvider<CacheService>((Ref ref) async {
  final SharedPreferences preferences = await ref.watch(
    sharedPreferencesProvider.future,
  );
  return CacheService(preferences);
});

final apiClientProvider = Provider<ApiClient>((Ref ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return AuthRepositoryImpl(
    AuthRemoteDatasource(
      apiClient: ref.watch(apiClientProvider),
      tokenStorage: ref.watch(tokenStorageProvider),
    ),
  );
});

final socialRepositoryProvider = FutureProvider<SocialRepository>((Ref ref) async {
  final CacheService cache = await ref.watch(cacheServiceProvider.future);
  return SocialRepositoryImpl(
    SocialRemoteDatasource(
      apiClient: ref.watch(apiClientProvider),
      cacheService: cache,
    ),
  );
});

final realtimeClientProvider = Provider<RealtimeClient>((Ref ref) {
  return RealtimeClient(ref.watch(appConfigProvider));
});

final liveRtcServiceProvider = Provider<LiveRtcService>((Ref ref) {
  return LiveRtcService();
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((
  Ref ref,
) {
  final AuthController controller = AuthController(
    ref.watch(authRepositoryProvider),
    () => ref.read(socialRepositoryProvider.future),
  );
  controller.restore();
  return controller;
});

final storiesProvider = FutureProvider<List<StoryItem>>((Ref ref) async {
  final SocialRepository repository = await ref.watch(
    socialRepositoryProvider.future,
  );
  return repository.getStories();
});

final liveStreamsProvider = FutureProvider<List<LiveStream>>((Ref ref) async {
  final SocialRepository repository = await ref.watch(
    socialRepositoryProvider.future,
  );
  return repository.getLiveStreams();
});

final chatRoomsProvider = FutureProvider<List<ChatRoom>>((Ref ref) async {
  final SocialRepository repository = await ref.watch(
    socialRepositoryProvider.future,
  );
  return repository.getChatRooms();
});

final fortuneServicesProvider = FutureProvider<List<FortuneService>>((
  Ref ref,
) async {
  final SocialRepository repository = await ref.watch(
    socialRepositoryProvider.future,
  );
  return repository.getFortuneServices();
});

final notificationsProvider = FutureProvider<List<NotificationItem>>((
  Ref ref,
) async {
  final SocialRepository repository = await ref.watch(
    socialRepositoryProvider.future,
  );
  return repository.getNotifications();
});

final adminMetricsProvider = FutureProvider<List<AdminMetric>>((Ref ref) async {
  final SocialRepository repository = await ref.watch(
    socialRepositoryProvider.future,
  );
  return repository.getAdminMetrics();
});

final explorePostsProvider = FutureProvider<List<ContentPost>>((Ref ref) async {
  final SocialRepository repository = await ref.watch(
    socialRepositoryProvider.future,
  );
  return repository.getExplorePosts();
});

class AuthController extends ChangeNotifier {
  AuthController(this._authRepository, this._socialRepositoryLoader);

  final AuthRepository _authRepository;
  final Future<SocialRepository> Function() _socialRepositoryLoader;

  AppUser? _user;
  bool _isBusy = false;
  String? _errorMessage;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  Future<void> restore() async {
    _user = await _authRepository.restoreSession();
    if (_user != null) {
      await _syncCoins();
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _runAuthAction(() async {
      _user = await _authRepository.signIn(email: email, password: password);
      await _syncCoins();
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _runAuthAction(() async {
      _user = await _authRepository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _syncCoins();
    });
  }

  Future<void> resetPassword(String email) async {
    await _authRepository.resetPassword(email);
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> followProfile(AppUser profile) async {
    try {
      final SocialRepository social = await _socialRepositoryLoader();
      final AppUser updated = await social.followUser(profile.id);
      _user = _user?.copyWith(
        following: (_user?.following ?? 0) + 1,
        coins: updated.coins > 0 ? updated.coins : _user?.coins,
      );
      notifyListeners();
    } on Object catch (error) {
      _errorMessage = error.toString();
      _user = _user?.copyWith(following: (_user?.following ?? 0) + 1);
      notifyListeners();
    }
  }

  void activatePremium() {
    _user = _user?.copyWith(
      tier: MembershipTier.vip,
      coins: (_user?.coins ?? 0) + 2500,
    );
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    final AppUser? current = _user;
    if (current == null || current.coins < amount) {
      _errorMessage = 'Yetersiz coin bakiyesi';
      notifyListeners();
      return false;
    }
    try {
      final SocialRepository social = await _socialRepositoryLoader();
      final int balance = await social.spendCoins(amount);
      _user = current.copyWith(coins: balance > 0 ? balance : current.coins - amount);
    } on Object {
      _user = current.copyWith(coins: current.coins - amount);
    }
    notifyListeners();
    return true;
  }

  Future<void> _syncCoins() async {
    try {
      final SocialRepository social = await _socialRepositoryLoader();
      final int balance = await social.getCoinBalance();
      if (balance > 0 && _user != null) {
        _user = _user!.copyWith(coins: balance);
      }
    } on Object {
      return;
    }
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on Object catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
