import 'package:flutter_riverpod/flutter_riverpod.dart';

class TwoFactorAuthStatus {
  final bool enabled;
  final String? method;
  final int backupCodesRemaining;

  TwoFactorAuthStatus({
    this.enabled = false,
    this.method,
    this.backupCodesRemaining = 0,
  });

  factory TwoFactorAuthStatus.fromJson(Map<String, dynamic> json) {
    return TwoFactorAuthStatus(
      enabled: json['enabled'] ?? false,
      method: json['method'],
      backupCodesRemaining: json['backupCodesRemaining'] ?? 0,
    );
  }
}

class TwoFactorAuthService {
  Future<Map<String, dynamic>> enableTwoFactor(String userId, {String method = 'totp'}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'secret': 'secret_code_here',
      'backupCodes': ['CODE1', 'CODE2', 'CODE3', 'CODE4', 'CODE5'],
    };
  }

  Future<bool> verifyCode(String userId, String code) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  Future<void> confirmEnable(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> disableTwoFactor(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<TwoFactorAuthStatus> getStatus(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return TwoFactorAuthStatus();
  }

  Future<Map<String, dynamic>> createSession(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'token': 'session_token',
      'code': '123456',
    };
  }

  Future<bool> verifySession(String token, String code) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }
}

final twoFactorAuthServiceProvider = Provider((ref) => TwoFactorAuthService());

final twoFactorStatusProvider = FutureProvider.family<TwoFactorAuthStatus, String>((ref, userId) async {
  final service = ref.watch(twoFactorAuthServiceProvider);
  return service.getStatus(userId);
});

class EnableTwoFactorNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  EnableTwoFactorNotifier(this.ref) : super(const AsyncValue.data({}));
  final Ref ref;

  Future<void> enable(String userId, {String method = 'totp'}) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(twoFactorAuthServiceProvider);
      final result = await service.enableTwoFactor(userId, method: method);
      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final enableTwoFactorNotifierProvider = StateNotifierProvider<EnableTwoFactorNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return EnableTwoFactorNotifier(ref);
});

class VerifyCodeNotifier extends StateNotifier<AsyncValue<bool>> {
  VerifyCodeNotifier(this.ref) : super(const AsyncValue.data(false));
  final Ref ref;

  Future<void> verify(String userId, String code) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(twoFactorAuthServiceProvider);
      final result = await service.verifyCode(userId, code);
      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final verifyCodeNotifierProvider = StateNotifierProvider<VerifyCodeNotifier, AsyncValue<bool>>((ref) {
  return VerifyCodeNotifier(ref);
});
