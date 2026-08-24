import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/presentation/providers/profile_hub_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import 'bot_account_guard.dart';

/// Oturum açmış kullanıcı bot mu? — `/api/me`, profil, cüzdan tek kaynak.
final isBotAccountProvider = Provider<bool>((ref) {
  final ext = ref.watch(profileExtendedProvider).valueOrNull;
  if (BotAccountGuard.fromJsonMap(ext?.raw)) return true;
  if (ext?.isBot == true) return true;
  final balances = ref.watch(walletBalancesProvider).valueOrNull;
  if (balances?.isBot == true) return true;
  return false;
});
