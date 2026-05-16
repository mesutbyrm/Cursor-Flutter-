import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'services.dart';

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
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final canlifalRepositoryProvider = FutureProvider<CanlifalRepository>((
  Ref ref,
) async {
  final CacheService cacheService = await ref.watch(
    cacheServiceProvider.future,
  );
  return CanlifalRepository(
    apiClient: ref.watch(apiClientProvider),
    cacheService: cacheService,
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
  return AuthController(ref.watch(authRepositoryProvider));
});

final storiesProvider = FutureProvider<List<StoryItem>>((Ref ref) async {
  final CanlifalRepository repository = await ref.watch(
    canlifalRepositoryProvider.future,
  );
  return repository.getStories();
});

final liveStreamsProvider = FutureProvider<List<LiveStream>>((Ref ref) async {
  final CanlifalRepository repository = await ref.watch(
    canlifalRepositoryProvider.future,
  );
  return repository.getLiveStreams();
});

final chatRoomsProvider = FutureProvider<List<ChatRoom>>((Ref ref) async {
  final CanlifalRepository repository = await ref.watch(
    canlifalRepositoryProvider.future,
  );
  return repository.getChatRooms();
});

final fortuneServicesProvider = FutureProvider<List<FortuneService>>((
  Ref ref,
) async {
  final CanlifalRepository repository = await ref.watch(
    canlifalRepositoryProvider.future,
  );
  return repository.getFortuneServices();
});

final notificationsProvider = FutureProvider<List<NotificationItem>>((
  Ref ref,
) async {
  final CanlifalRepository repository = await ref.watch(
    canlifalRepositoryProvider.future,
  );
  return repository.getNotifications();
});

final adminMetricsProvider = FutureProvider<List<AdminMetric>>((Ref ref) async {
  final CanlifalRepository repository = await ref.watch(
    canlifalRepositoryProvider.future,
  );
  return repository.getAdminMetrics();
});

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AppUser? _user = CanlifalSeed.currentUser;
  bool _isBusy = false;
  String? _errorMessage;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn({required String email, required String password}) async {
    return _runAuthAction(() async {
      _user = await _repository.signIn(email: email, password: password);
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _runAuthAction(() async {
      _user = await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
    });
  }

  Future<void> resetPassword(String email) async {
    await _repository.resetPassword(email);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    notifyListeners();
  }

  void follow(AppUser profile) {
    _user = _user?.copyWith(following: (_user?.following ?? 0) + 1);
    notifyListeners();
  }

  void activatePremium() {
    _user = _user?.copyWith(
      tier: MembershipTier.vip,
      coins: (_user?.coins ?? 0) + 2500,
    );
    notifyListeners();
  }

  bool spendCoins(int amount) {
    final AppUser? current = _user;
    if (current == null || current.coins < amount) {
      _errorMessage = 'Yetersiz coin bakiyesi';
      notifyListeners();
      return false;
    }
    _user = current.copyWith(coins: current.coins - amount);
    notifyListeners();
    return true;
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
