import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/wallet_remote_datasource_extended.dart';
import '../../domain/platform_commission_rates.dart';
import '../../domain/withdrawal_request.dart';

final walletRemoteExtendedProvider = Provider<WalletRemoteDataSourceExtended>(
  (ref) => WalletRemoteDataSourceExtended(ref.watch(dioProvider)),
);

final platformCommissionRatesProvider =
    FutureProvider<PlatformCommissionRates>((ref) async {
  return ref.watch(walletRemoteExtendedProvider).fetchCommissionRates();
});

final withdrawalHistoryProvider =
    FutureProvider<List<WithdrawalRequest>>((ref) async {
  return ref.watch(walletRemoteExtendedProvider).fetchWithdrawals();
});
