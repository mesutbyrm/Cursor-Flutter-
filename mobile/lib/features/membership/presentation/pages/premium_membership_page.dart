import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/payment_defaults.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../profile/data/jeton_packages_catalog.dart';
import '../../../profile/domain/entities/jeton_package_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../../profile/presentation/widgets/jeton_checkout_flow.dart';
import '../../data/membership_remote_datasource.dart';
import '../../domain/membership_package_entity.dart';
import '../widgets/premium_membership_widgets.dart';

final _membershipRemoteProvider = Provider<MembershipRemoteDataSource>((ref) {
  return MembershipRemoteDataSource(ref.watch(dioProvider));
});

final membershipCatalogProvider =
    FutureProvider.autoDispose<MembershipCatalogEntity>((ref) async {
  WalletBalances wallet;
  try {
    wallet = await ref.watch(walletBalancesProvider.future).timeout(
          const Duration(seconds: 15),
        );
  } catch (_) {
    wallet = const WalletBalances();
  }
  return ref.watch(_membershipRemoteProvider).loadCatalog(wallet);
});

/// Gold / Premium üyelik — API yoksa varsayılan paketler; ödeme WhatsApp/Papara/Havale.
class PremiumMembershipPage extends ConsumerWidget {
  const PremiumMembershipPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(membershipCatalogProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0618),
      body: PremiumMembershipScaffold(
        child: catalog.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => _ErrorBody(message: ApiException.userMessage(e)),
          data: (cat) => RefreshIndicator(
            color: AppColors.accentPurple,
            onRefresh: () async {
              ref.invalidate(membershipCatalogProvider);
              ref.invalidate(walletBalancesProvider);
              ref.invalidate(paymentConfigProvider);
              await ref.read(membershipCatalogProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).top + 8,
                  ),
                ),
                SliverToBoxAdapter(
                  child: PremiumMembershipBody(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PremiumMembershipHeader(
                          onBack: () => context.pop(),
                          title: 'Gold Üyelik',
                          subtitle:
                              'Premium, Gold ve Diamond paketleri · site ile aynı',
                        ),
                        const SizedBox(height: 20),
                        const PremiumFeatureGrid(),
                        const SizedBox(height: 20),
                        if (_hasActiveMembership(cat)) ...[
                          PremiumActiveMembershipCard(
                            tierLabel: _activeTierLabel(cat),
                            daysRemaining:
                                cat.daysRemaining ?? cat.activePackage?.daysRemaining ?? 0,
                            onExtend: () => _purchase(context, ref, cat, _activePackage(cat)),
                          ),
                          const SizedBox(height: 16),
                        ],
                        PremiumBalanceLines(
                          jeton: cat.jetonBalance,
                          cfc: cat.cfcBalance,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ödeme: WhatsApp ${PaymentDefaults.whatsapp} · '
                          'Papara ${PaymentDefaults.papara}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted.withValues(alpha: 0.9),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...cat.packages.map(
                          (p) => PremiumTierCard(
                            package: p,
                            onBuy: () => _purchase(context, ref, cat, p),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static MembershipPackageEntity _activePackage(MembershipCatalogEntity cat) {
    return cat.packages.firstWhere(
      (p) => p.id == cat.currentMembership.toLowerCase(),
      orElse: () => cat.packages.firstWhere(
        (p) => p.isActive,
        orElse: () => cat.packages.first,
      ),
    );
  }

  static bool _hasActiveMembership(MembershipCatalogEntity cat) {
    final d = cat.daysRemaining ?? cat.activePackage?.daysRemaining ?? 0;
    return d > 0 && cat.currentMembership.toLowerCase() != 'basic';
  }

  static String _activeTierLabel(MembershipCatalogEntity cat) {
    final id = cat.currentMembership;
    final match = cat.packages.where((p) => p.id == id);
    if (match.isNotEmpty) return match.first.title;
    return id.isEmpty ? 'Gold' : id[0].toUpperCase() + id.substring(1);
  }

  static Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    MembershipCatalogEntity cat,
    MembershipPackageEntity pkg,
  ) async {
    final rate = ref.read(walletBalancesProvider).valueOrNull?.jetonTlRate ??
        kDefaultJetonTlRate;

    try {
      await ref.read(dioProvider).safePost<Map<String, dynamic>>(
        ApiEndpoints.membershipPurchase,
        data: {'tierId': pkg.id},
      );
      ref.invalidate(membershipCatalogProvider);
      ref.invalidate(walletBalancesProvider);
      if (context.mounted) {
        final active = pkg.isActive && (pkg.daysRemaining ?? 0) > 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              active
                  ? '${pkg.title} üyeliğiniz uzatıldı'
                  : '${pkg.title} üyeliği aktif',
            ),
          ),
        );
      }
      return;
    } on ApiException catch (e) {
      if (e.message.contains('Yetersiz jeton')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
          context.push('/jeton-store');
        }
        return;
      }
    } catch (_) {}

    if (!context.mounted) return;

    final priceTry = pkg.priceJeton * rate;
    final jetonPkg = JetonPackageEntity(
      id: 'membership_${pkg.id}',
      title: '${pkg.title} Üyelik · ${pkg.durationDays} gün',
      coins: pkg.priceJeton,
      priceTry: priceTry,
      badge: pkg.isActive ? 'Uzat' : null,
    );
    final priceText = priceTry == priceTry.roundToDouble()
        ? '₺${priceTry.toInt()}'
        : '₺${priceTry.toStringAsFixed(2)}';

    openJetonCheckoutFlow(
      context,
      ref,
      package: jetonPkg,
      priceText: '$priceText (${pkg.priceJeton} jeton)',
      paymentNotes: 'Gold üyelik · ${pkg.title} · ${pkg.durationDays} gün',
      onDone: () {
        ref.invalidate(membershipCatalogProvider);
        ref.invalidate(walletBalancesProvider);
        ref.invalidate(allPaymentRequestsProvider);
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveLayout.pagePadding(context),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
