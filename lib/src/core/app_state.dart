import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';
import 'app_models.dart';

final tokenStorageProvider = Provider<SecureTokenStorage>(
  (ref) => const SecureTokenStorage(FlutterSecureStorage()),
);

final apiProvider = Provider<CanlifalApi>(
  (ref) => CanlifalApi(ref.watch(tokenStorageProvider)),
);

final sessionProvider = ChangeNotifierProvider<SessionController>(
  (ref) => SessionController(
    ref.watch(apiProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final feedProvider = FutureProvider.autoDispose<List<FeedPost>>(
  (ref) => ref.watch(apiProvider).feed(),
);

final liveStreamsProvider = FutureProvider.autoDispose<List<LiveStream>>(
  (ref) => ref.watch(apiProvider).liveStreams(),
);

final roomsProvider = FutureProvider.autoDispose<List<ChatRoom>>(
  (ref) => ref.watch(apiProvider).rooms(),
);

final giftsProvider = FutureProvider.autoDispose<List<GiftType>>(
  (ref) => ref.watch(apiProvider).gifts(),
);

final trendsProvider = FutureProvider.autoDispose<List<TrendItem>>(
  (ref) => ref.watch(apiProvider).trends(),
);

final coinInfoProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.watch(apiProvider).coinInfo(),
);

class SessionController extends ChangeNotifier {
  SessionController(this._api, this._tokens);

  final CanlifalApi _api;
  final SecureTokenStorage _tokens;

  AppUser? user;
  bool loading = false;
  String? error;

  bool get isAuthenticated => user != null;

  Future<void> login(String email, String password) async {
    await _run(() async {
      final session = await _api.login(email, password);
      user = session.user;
    });
  }

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String birthDate,
    required String birthTime,
    String? referralCode,
  }) async {
    await _run(() async {
      final session = await _api.register(
        name: name,
        username: username,
        email: email,
        password: password,
        birthDate: birthDate,
        birthTime: birthTime,
        referralCode: referralCode,
      );
      user = session.user;
    });
  }

  void continueAsGuest() {
    user = AppUser.guest;
    error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokens.clear();
    user = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (user == null || user?.id == 'guest') return;
    await _run(() async {
      user = await _api.profile();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (exception) {
      error = exception.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
