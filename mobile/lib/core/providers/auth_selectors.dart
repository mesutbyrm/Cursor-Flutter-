import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';

/// Dar rebuild — yalnızca kullanıcı kimliği.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(
    authControllerProvider.select((a) => a.valueOrNull?.id),
  );
});

/// Tek jeton kaynağı — cüzdan API öncelikli, auth yalnızca ilk seed.
final currentUserCoinBalanceProvider = Provider<int>((ref) {
  final walletJeton =
      ref.watch(walletBalancesProvider.select((w) => w.valueOrNull?.jeton));
  if (walletJeton != null) return walletJeton;
  return ref.watch(
    authControllerProvider.select((a) => a.valueOrNull?.coinBalance ?? 0),
  );
});
