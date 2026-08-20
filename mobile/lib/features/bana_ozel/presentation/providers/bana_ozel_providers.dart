import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/bana_ozel_remote_datasource.dart';
import '../../data/repositories/bana_ozel_repository_impl.dart';
import '../../domain/entities/bana_ozel_entities.dart';
import '../../domain/repositories/bana_ozel_repository.dart';

final banaOzelRemoteProvider = Provider<BanaOzelRemoteDataSource>((ref) {
  return BanaOzelRemoteDataSource(ref.watch(dioProvider));
});

final banaOzelRepositoryProvider = Provider<BanaOzelRepository>((ref) {
  return BanaOzelRepositoryImpl(ref.watch(banaOzelRemoteProvider));
});

final banaOzelCatalogProvider =
    AsyncNotifierProvider<BanaOzelCatalogNotifier, BanaOzelCatalogEntity>(
  BanaOzelCatalogNotifier.new,
);

class BanaOzelCatalogNotifier extends AsyncNotifier<BanaOzelCatalogEntity> {
  @override
  Future<BanaOzelCatalogEntity> build() async {
    ref.listen(authControllerProvider, (prev, next) {
      final prevId = prev?.valueOrNull?.id;
      final nextId = next.valueOrNull?.id;
      if (prevId != nextId) {
        refresh();
      }
    });
    return ref.read(banaOzelRepositoryProvider).fetchCatalog();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(banaOzelRepositoryProvider).fetchCatalog(),
    );
  }

  void applyOpenResult(BanaOzelOpenResultEntity result) {
    final current = state.valueOrNull;
    if (current == null) return;
    final balance = resolveJetonBalanceAfterOpen(
      currentBalance: current.jetonBalance,
      result: result,
    );
    state = AsyncData(
      BanaOzelCatalogEntity(
        items: current.items,
        jetonBalance: balance,
        streak: result.streak ?? current.streak,
        todayTasks: current.todayTasks,
      ),
    );
  }
}
