import '../../../features/wallet/domain/wallet_balances.dart';
import '../domain/currency_branding_snapshot.dart';
import '../domain/economy_wallet_snapshot.dart';
import '../data/economy_wallet_remote_datasource.dart';

/// Birleşik cüzdan ucu başarısız olursa mevcut `WalletBalances` ile devam eder.
class EconomyWalletAdapter {
  EconomyWalletAdapter(this._remote);

  final EconomyWalletRemoteDataSource _remote;

  Future<EconomyWalletSnapshot?> fetchUnified({
    int limit = 25,
    int offset = 0,
    String currency = 'all',
  }) async {
    return _remote.fetchWallet(
      limit: limit,
      offset: offset,
      currency: currency,
    );
  }

  EconomyWalletSnapshot fromLegacyBalances(
    WalletBalances balances, {
    CurrencyBrandingSnapshot branding = CurrencyBrandingSnapshot.defaults,
  }) {
    return EconomyWalletSnapshot(
      cfc: balances.cfc,
      jeton: balances.jeton,
      branding: branding,
      referralCreditsEarned: balances.totalEarnedJeton ?? 0,
      tellerEarnings: balances.approvedEarningsTl?.round() ?? 0,
      canWithdraw: (balances.withdrawableTl ?? 0) > 0,
      minWithdrawal: balances.withdrawalLimit,
      jetonTlRate: balances.jetonTlRate ?? 0,
      estimatedTl: balances.withdrawableTl ?? 0,
    );
  }

  Future<EconomyWalletSnapshot> fetchWithFallback({
    required Future<WalletBalances> Function() legacyFetch,
    CurrencyBrandingSnapshot branding = CurrencyBrandingSnapshot.defaults,
    int limit = 25,
  }) async {
    try {
      final unified = await fetchUnified(limit: limit);
      if (unified != null) return unified;
    } catch (_) {}
    final legacy = await legacyFetch();
    return fromLegacyBalances(legacy, branding: branding);
  }
}
