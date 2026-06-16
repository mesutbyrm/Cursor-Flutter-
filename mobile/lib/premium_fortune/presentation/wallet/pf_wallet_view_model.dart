import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/pf_config.dart';
import '../../core/di/pf_providers.dart';
import '../../domain/entities/pf_wallet.dart';
import '../../domain/repositories/pf_wallet_repository.dart';

class PfWalletViewModel extends AsyncNotifier<List<PfWalletTransaction>> {
  @override
  Future<List<PfWalletTransaction>> build() async {
    final user = ref.watch(pfEffectiveUserProvider);
    if (user == null) return [];
    final result =
        await ref.read(pfWalletRepositoryProvider).getTransactions(user.id);
    return result.valueOrNull ?? [];
  }

  PfWalletRepository get _repo => ref.read(pfWalletRepositoryProvider);

  List<PfCreditPackage> get packages => _repo.getPackages();

  Future<String?> purchasePackage(PfCreditPackage package) async {
    final user = ref.read(pfEffectiveUserProvider);
    if (user == null) return 'Giriş gerekli';

    final provider = PfConfig.hasStripe ? 'stripe' : 'iyzico';
    final result = await _repo.purchasePackage(
      userId: user.id,
      package: package,
      paymentProvider: provider,
    );
    return result.fold(
      onSuccess: (_) {
        ref.invalidateSelf();
        return null;
      },
      onFailure: (f) => f.message,
    );
  }

  Future<String?> redeemCoupon(String code) async {
    final user = ref.read(pfEffectiveUserProvider);
    if (user == null) return 'Giriş gerekli';

    final result = await _repo.redeemCoupon(user.id, code);
    return result.fold(
      onSuccess: (_) {
        ref.invalidateSelf();
        return null;
      },
      onFailure: (f) => f.message,
    );
  }
}


final pfWalletViewModelProvider =
    AsyncNotifierProvider<PfWalletViewModel, List<PfWalletTransaction>>(
  PfWalletViewModel.new,
);
