import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../data/jeton_packages_catalog.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../providers/profile_providers.dart';
import '../widgets/currency_usage_card.dart';
import '../widgets/jeton_checkout_flow.dart';
import '../widgets/jeton_store_widgets.dart';

/// Jeton mağazası — responsive mockup (`/api/jeton`, `/api/user/credits`).
class JetonPurchasePage extends ConsumerWidget {
  const JetonPurchasePage({super.key});

  void _openCheckout(
    BuildContext context,
    WidgetRef ref,
    JetonPackageEntity package,
    String priceText,
  ) {
    openJetonCheckoutFlow(
      context,
      ref,
      package: package,
      priceText: priceText,
      onDone: () {
        ref.invalidate(walletBalancesProvider);
        ref.invalidate(jetonPackagesProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(jetonPackagesProvider);
    final wallet = ref.watch(walletBalancesProvider);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const JetonStoreBackdrop(),
          RefreshIndicator(
            color: AppThemeColors.accentPurple,
            onRefresh: () async {
              ref.invalidate(jetonPackagesProvider);
              ref.invalidate(walletBalancesProvider);
              await ref.read(jetonPackagesProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: top + 8)),
                SliverToBoxAdapter(
                  child: ResponsiveConstrained(
                    child: Padding(
                      padding: ResponsiveLayout.pagePadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _JetonStoreHeader(onBack: () => context.pop()),
                          SizedBox(height: 16),
                          const CurrencyUsageCard.jeton(),
                          SizedBox(height: 20),
                          wallet.when(
                            data: (b) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                JetonStoreBalanceRow(
                                  jeton: b.jeton,
                                  cfc: b.cfc,
                                ),
                                if (_isGoldMember(
                                  b.membership,
                                  b.membershipDaysRemaining,
                                )) ...[
                                  SizedBox(height: 12),
                                  JetonGoldMemberBanner(
                                    onTap: () =>
                                        context.push('/premium-membership'),
                                  ),
                                ],
                              ],
                            ),
                            loading: () => Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            error: (e, _) => Text(
                              ApiException.userMessage(e),
                              style: TextStyle(color: context.colors.onSurfaceMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                packages.when(
                  loading: () => _JetonPackagesContent(
                    pageContext: context,
                    ref: ref,
                    list: kFallbackJetonPackages,
                    wallet: wallet,
                    onCheckout: (p, price) => _openCheckout(context, ref, p, price),
                    isRefreshing: true,
                  ),
                  error: (e, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: ResponsiveConstrained(
                      child: Padding(
                        padding: ResponsiveLayout.pagePadding(context),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off_rounded,
                                size: 48,
                                color: context.colors.onSurfaceMuted.withValues(alpha: 0.8)),
                            SizedBox(height: 12),
                            Text(
                              ApiException.userMessage(e),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            FilledButton(
                              onPressed: () =>
                                  ref.invalidate(jetonPackagesProvider),
                              child: Text('Tekrar dene'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  data: (list) => _JetonPackagesContent(
                    pageContext: context,
                    ref: ref,
                    list: list.isEmpty ? kFallbackJetonPackages : list,
                    wallet: wallet,
                    onCheckout: (p, price) => _openCheckout(context, ref, p, price),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _isGoldMember(String? membership, int? days) {
    if (membership?.toLowerCase() != 'gold') return false;
    return (days ?? 0) > 0;
  }
}

class _JetonStoreHeader extends StatelessWidget {
  const _JetonStoreHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ProGlassCard(
            blur: 10,
            animateIn: false,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(28),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: onBack,
            ),
          ),
        ),
        SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppThemeColors.coinGold.withValues(alpha: 0.2),
            border: Border.all(
              color: AppThemeColors.coinGold.withValues(alpha: 0.55),
              width: 2,
            ),
            boxShadow: AppThemeColors.glowShadow(AppThemeColors.coinGold, blur: 18),
          ),
          child: Icon(
            Icons.monetization_on_rounded,
            color: AppThemeColors.coinGold,
            size: 36,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Jeton Satın Al',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.colors.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _JetonPackagesContent extends StatelessWidget {
  const _JetonPackagesContent({
    required this.pageContext,
    required this.ref,
    required this.list,
    required this.wallet,
    required this.onCheckout,
    this.isRefreshing = false,
  });

  final BuildContext pageContext;
  final WidgetRef ref;
  final List<JetonPackageEntity> list;
  final AsyncValue<WalletBalances> wallet;
  final void Function(JetonPackageEntity package, String priceText) onCheckout;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final grid = jetonGridPackages(list);
    final hero = jetonHeroPackage(list);
    final rate = wallet.valueOrNull?.jetonTlRate ?? kDefaultJetonTlRate;

    return SliverToBoxAdapter(
      child: ResponsiveConstrained(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(
            pageContext,
            bottom: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isRefreshing)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (grid.isNotEmpty)
                _ResponsivePackageGrid(
                  packages: grid,
                  onTap: (p) => onCheckout(p, formatJetonPrice(p)),
                ),
              if (hero != null) ...[
                JetonPackageTile(
                  package: hero,
                  priceText: formatJetonPrice(hero),
                  fullWidth: true,
                  onTap: () => onCheckout(hero, formatJetonPrice(hero)),
                ),
              ],
              SizedBox(height: 24),
              JetonCustomAmountSection(
                tlRate: rate,
                onPurchase: onCheckout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsivePackageGrid extends StatelessWidget {
  const _ResponsivePackageGrid({
    required this.packages,
    required this.onTap,
  });

  final List<JetonPackageEntity> packages;
  final void Function(JetonPackageEntity) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = ResponsiveLayout.gridColumns(constraints.maxWidth);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: ResponsiveLayout.gridAspectRatio(cols),
            ),
            itemCount: packages.length,
            itemBuilder: (context, i) {
              final p = packages[i];
              return JetonPackageTile(
                package: p,
                priceText: formatJetonPrice(p),
                onTap: () => onTap(p),
              );
            },
          ),
        );
      },
    );
  }
}
