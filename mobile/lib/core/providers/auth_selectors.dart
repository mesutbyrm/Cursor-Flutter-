import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

/// Dar rebuild — yalnızca kullanıcı kimliği.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(
    authControllerProvider.select((a) => a.valueOrNull?.id),
  );
});

/// Dar rebuild — jeton bakiyesi (kartlarda auth yerine).
final currentUserCoinBalanceProvider = Provider<int>((ref) {
  return ref.watch(
    authControllerProvider.select((a) => a.valueOrNull?.coinBalance ?? 0),
  );
});
