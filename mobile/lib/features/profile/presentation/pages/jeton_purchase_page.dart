import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../data/jeton_packages_catalog.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../providers/profile_providers.dart';
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
      backgroundColor: const Color(0xFF0B0618),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const JetonStoreBackdrop(),
          RefreshIndicator(
            color: AppColors.accentPurple,
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
                          const SizedBox(height: 20),
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
                                  const SizedBox(height: 12),
                                  JetonGoldMemberBanner(
                                    onTap: () =>
                                        context.push('/premium-membership'),
                                  ),
                                ],
                              ],
                            ),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            error: (e, _) => Text(
                              ApiException.userMessage(e),
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                packages.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
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
                                color: AppColors.textMuted.withValues(alpha: 0.8)),
                            const SizedBox(height: 12),
                            Text(
                              ApiException.userMessage(e),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () =>
                                  ref.invalidate(jetonPackagesProvider),
                              child: const Text('Tekrar dene'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  data: (list) {
                    final display = list.isEmpty
                        ? List<JetonPackageEntity>.from(kFallbackJetonPackages)
                        : list;
                    final grid = jetonGridPackages(display);
                    final hero = jetonHeroPackage(display);
                    final rate =
                        wallet.valueOrNull?.jetonTlRate ?? kDefaultJetonTlRate;

                    return SliverToBoxAdapter(
                      child: ResponsiveConstrained(
                        child: Padding(
                          padding: ResponsiveLayout.pagePadding(
                            context,
                            bottom: 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (grid.isNotEmpty)
                                _ResponsivePackageGrid(
                                  packages: grid,
                                  onTap: (p) => _openCheckout(
                                    context,
                                    ref,
                                    p,
                                    formatJetonPrice(p),
                                  ),
                                ),
                              if (hero != null) ...[
                                const SizedBox(height: 10),
                                JetonPackageTile(
                                  package: hero,
                                  priceText: formatJetonPrice(hero),
                                  fullWidth: true,
                                  onTap: () => _openCheckout(
                                    context,
                                    ref,
                                    hero,
                                    formatJetonPrice(hero),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              JetonCustomAmountSection(
                                tlRate: rate,
                                onPurchase: (p, price) =>
                                    _openCheckout(context, ref, p, price),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
          child: Material(
            color: Colors.white.withValues(alpha: 0.08),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: onBack,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.coinGold.withValues(alpha: 0.2),
            border: Border.all(
              color: AppColors.coinGold.withValues(alpha: 0.55),
              width: 2,
            ),
            boxShadow: AppColors.glowShadow(AppColors.coinGold, blur: 18),
          ),
          child: const Icon(
            Icons.monetization_on_rounded,
            color: AppColors.coinGold,
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Jeton Satın Al',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ],
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
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
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
        );
      },
    );
  }
}
