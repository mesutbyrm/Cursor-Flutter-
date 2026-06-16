import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/pf_providers.dart';
import '../../domain/entities/pf_user.dart';
import '../../domain/repositories/pf_auth_repository.dart';

class PfAuthViewModel extends AsyncNotifier<PfUser?> {
  @override
  Future<PfUser?> build() async {
    final user = ref.watch(pfEffectiveUserProvider);
    return user;
  }

  PfAuthRepository get _repo => ref.read(pfAuthRepositoryProvider);

  Future<String?> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    final result = await _repo.signInWithEmail(email, password);
    return result.fold(
      onSuccess: (user) {
        state = AsyncData(user);
        return null;
      },
      onFailure: (f) {
        state = const AsyncData(null);
        return f.message;
      },
    );
  }

  Future<String?> register(String email, String password, String name) async {
    state = const AsyncLoading();
    final result = await _repo.registerWithEmail(email, password, name);
    return result.fold(
      onSuccess: (user) {
        state = AsyncData(user);
        return null;
      },
      onFailure: (f) {
        state = const AsyncData(null);
        return f.message;
      },
    );
  }

  Future<String?> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await _repo.signInWithGoogle();
    return result.fold(
      onSuccess: (user) {
        state = AsyncData(user);
        return null;
      },
      onFailure: (f) {
        state = const AsyncData(null);
        return f.message;
      },
    );
  }

  Future<String?> signInWithApple() async {
    state = const AsyncLoading();
    final result = await _repo.signInWithApple();
    return result.fold(
      onSuccess: (user) {
        state = AsyncData(user);
        return null;
      },
      onFailure: (f) {
        state = const AsyncData(null);
        return f.message;
      },
    );
  }

  void continueAsGuest() {
    ref.read(pfGuestModeProvider.notifier).state = true;
    state = AsyncData(ref.read(pfDemoUserProvider));
  }

  Future<void> signOut() async {
    await _repo.signOut();
    ref.read(pfGuestModeProvider.notifier).state = false;
    state = const AsyncData(null);
  }

  Future<String?> updateProfile({
    String? displayName,
    String? zodiacSign,
  }) async {
    final result = await _repo.updateProfile(
      displayName: displayName,
      zodiacSign: zodiacSign,
    );
    return result.fold(
      onSuccess: (user) {
        state = AsyncData(user);
        return null;
      },
      onFailure: (f) => f.message,
    );
  }
}

final pfAuthViewModelProvider =
    AsyncNotifierProvider<PfAuthViewModel, PfUser?>(PfAuthViewModel.new);
