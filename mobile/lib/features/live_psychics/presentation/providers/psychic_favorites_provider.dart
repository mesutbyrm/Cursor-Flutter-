import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/psychic_entity.dart';
import '../providers/live_psychics_providers.dart';

/// Oturum açık kullanıcının favori falcı kimlikleri.
class PsychicFavoritesController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final authed = ref.watch(authControllerProvider).valueOrNull;
    if (authed == null) return const {};
    final list =
        await ref.read(livePsychicsRepositoryProvider).fetchFavoritePsychics();
    return list.map((p) => p.id).toSet();
  }

  Future<bool> toggle(String tellerId) async {
    final key = tellerId.trim();
    if (key.isEmpty) return false;
    final favored =
        await ref.read(livePsychicsRepositoryProvider).toggleFavoritePsychic(key);
    final current = {...?state.valueOrNull};
    if (favored) {
      current.add(key);
    } else {
      current.remove(key);
    }
    state = AsyncData(current);
    return favored;
  }

  void refresh() => ref.invalidateSelf();
}

final psychicFavoritesProvider =
    AsyncNotifierProvider<PsychicFavoritesController, Set<String>>(
  PsychicFavoritesController.new,
);

final psychicFavoritePsychicsProvider =
    FutureProvider.autoDispose<List<PsychicEntity>>((ref) async {
  return ref.read(livePsychicsRepositoryProvider).fetchFavoritePsychics();
});
