import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/pf_providers.dart';
import '../../domain/entities/pf_coffee_reading.dart';
import '../../domain/repositories/pf_coffee_repository.dart';

class PfCoffeeViewModel extends AsyncNotifier<List<PfCoffeeReading>> {
  @override
  Future<List<PfCoffeeReading>> build() async {
    final user = ref.watch(pfEffectiveUserProvider);
    if (user == null) return [];
    final result = await ref.read(pfCoffeeRepositoryProvider).getHistory(user.id);
    return result.valueOrNull ?? [];
  }

  PfCoffeeRepository get _repo => ref.read(pfCoffeeRepositoryProvider);

  Future<({PfCoffeeReading? reading, String? error})> analyzePhoto(
    String localPath,
  ) async {
    final user = ref.read(pfEffectiveUserProvider);
    if (user == null) return (reading: null, error: 'Giriş gerekli');

    state = const AsyncLoading();
    final result = await _repo.analyzePhoto(
      userId: user.id,
      localImagePath: localPath,
    );

    return result.fold(
      onSuccess: (reading) {
        ref.invalidateSelf();
        return (reading: reading, error: null);
      },
      onFailure: (f) {
        ref.invalidateSelf();
        return (reading: null, error: f.message);
      },
    );
  }
}

final pfCoffeeViewModelProvider =
    AsyncNotifierProvider<PfCoffeeViewModel, List<PfCoffeeReading>>(
  PfCoffeeViewModel.new,
);
