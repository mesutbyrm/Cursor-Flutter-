import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/pf_providers.dart';
import '../../domain/entities/pf_tarot_reading.dart';
import '../../domain/repositories/pf_tarot_repository.dart';

final pfSelectedTarotCardsProvider = StateProvider<List<String>>((_) => []);

class PfTarotViewModel extends AsyncNotifier<List<PfTarotReading>> {
  @override
  Future<List<PfTarotReading>> build() async {
    final user = ref.watch(pfEffectiveUserProvider);
    if (user == null) return [];
    final result = await ref.read(pfTarotRepositoryProvider).getHistory(user.id);
    return result.valueOrNull ?? [];
  }

  PfTarotRepository get _repo => ref.read(pfTarotRepositoryProvider);

  List<PfTarotCard> get deck => _repo.getDeck();

  void toggleCard(String id) {
    final current = List<String>.from(ref.read(pfSelectedTarotCardsProvider));
    if (current.contains(id)) {
      current.remove(id);
    } else if (current.length < 3) {
      current.add(id);
    }
    ref.read(pfSelectedTarotCardsProvider.notifier).state = current;
  }

  void clearSelection() {
    ref.read(pfSelectedTarotCardsProvider.notifier).state = [];
  }

  Future<({PfTarotReading? reading, String? error})> createReading(
    PfTarotMode mode,
  ) async {
    final user = ref.read(pfEffectiveUserProvider);
    if (user == null) return (reading: null, error: 'Giriş gerekli');
    final selectedCardIds = ref.read(pfSelectedTarotCardsProvider);
    if (selectedCardIds.isEmpty) {
      return (reading: null, error: 'En az 1 kart seçin');
    }

    state = const AsyncLoading();
    final result = await _repo.createReading(
      userId: user.id,
      mode: mode,
      selectedCardIds: List.from(selectedCardIds),
    );

    return result.fold(
      onSuccess: (reading) {
        clearSelection();
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

final pfTarotViewModelProvider =
    AsyncNotifierProvider<PfTarotViewModel, List<PfTarotReading>>(
  PfTarotViewModel.new,
);
