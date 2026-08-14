import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/content/currency_usage_info.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../profile/domain/entities/jeton_package_entity.dart';
import '../../../profile/domain/entities/payment_method_entity.dart';
import '../../../profile/presentation/providers/payment_requests_notifier.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/jeton_checkout_flow.dart';
import '../../../profile/presentation/widgets/payment_methods_summary_line.dart';
import '../../domain/membership_model.dart';
import '../../../profile/presentation/providers/profile_hub_providers.dart';
import '../controllers/membership_controller.dart';
import '../widgets/common_benefits.dart';
import '../widgets/feature_table.dart';
import '../widgets/membership_card.dart';
import '../widgets/membership_checkout_sheet.dart';
import '../widgets/membership_cfc_checkout_flow.dart';
import '../widgets/membership_pending_payment_banner.dart';
import '../widgets/membership_payment_methods_summary.dart';
import '../widgets/support_footer.dart';
import '../widgets/token_package_card.dart';

/// Pixel-perfect Üyelikler sayfası (Material 3 · Canlifal premium).
class MembershipPage extends ConsumerWidget {
  const MembershipPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(membershipControllerProvider);
    final catalogAsync = ref.watch(membershipCatalogProvider);
    final padding = ResponsiveLayout.pagePadding(context);
    final pendingRequests = ref.watch(paymentRequestsNotifierProvider);

    return Scaffold(
      backgroundColor: MembershipCatalogData.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _MembershipBackdrop(),
          SafeArea(
            child: catalogAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MembershipCatalogData.gold,
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: padding,
                  child: Text(
                    ApiException.userMessage(e),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              data: (_) => RefreshIndicator(
                color: MembershipCatalogData.gold,
                onRefresh: () =>
                    ref.read(membershipControllerProvider.notifier).refresh(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          padding.left,
                          8,
                          padding.right,
                          0,
                        ),
                        child: _MembershipAppBar(
                          diamondLabel: ui.formattedDiamondBalance,
                          onBack: () => context.pop(),
                          onAddDiamonds: () => context.push('/jeton-store'),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          padding.left,
                          18,
                          padding.right,
                          28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (pendingRequests.valueOrNull
                                    ?.any((r) =>
                                        r.isMembershipCheckout && r.isPending) ==
                                true) ...[
                              const MembershipPendingPaymentBanner(),
                            ],
                            if (ui.isMembershipExpired) ...[
                              _ExpiredMembershipBanner(
                                label: ui.currentMembershipLabel,
                                onRenew: () => _purchaseSelected(context, ref),
                              ),
                              const SizedBox(height: 16),
                            ] else if (ui.hasActivePaidMembership) ...[
                              _ActiveBanner(
                                label: ui.currentMembershipLabel,
                                days: ui.daysRemaining,
                                onExtend: () => _purchaseSelected(context, ref),
                              ),
                              const SizedBox(height: 16),
                            ],
                            SizedBox(
                              height: 236,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: ui.tiers.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final tier = ui.tiers[i];
                                  return MembershipCard(
                                    tier: tier,
                                    selected: ui.selectedTier == tier.id,
                                    animationIndex: i,
                                    onTap: () => ref
                                        .read(
                                          membershipControllerProvider
                                              .notifier,
                                        )
                                        .selectTier(tier.id),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Tüm Üyelik Özellikleri',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            MembershipFeatureTable(
                              selectedTier: ui.selectedTier,
                              tiers: ui.tiers,
                            ),
                            const SizedBox(height: 22),
                            _UpgradeBanner(
                              onBuyTokens: () => context.push('/jeton-store'),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Jeton Paketleri',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Üyelik paketleri · jeton alımında indirim yok',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 220,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: ui.tokenPackages.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final pkg = ui.tokenPackages[i];
                                  return TokenPackageCard(
                                    package: pkg,
                                    selected:
                                        ui.selectedTokenPackage == pkg.tierId,
                                    animationIndex: i,
                                    onTap: () => ref
                                        .read(
                                          membershipControllerProvider
                                              .notifier,
                                        )
                                        .selectTokenPackage(pkg.tierId),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: () =>
                                  _purchaseSelected(context, ref),
                              style: FilledButton.styleFrom(
                                backgroundColor: MembershipCatalogData.gold,
                                foregroundColor: const Color(0xFF1A1030),
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                '${ui.selectedTierModel.title} Üyeliği Satın Al · ₺${ui.selectedTierModel.monthlyPriceTry}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const MembershipPaymentMethodsSummary(),
                            const SizedBox(height: 28),
                            const MembershipCommonBenefits(),
                            const SizedBox(height: 28),
                            const MembershipSupportFooter(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _purchaseSelected(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ui = ref.read(membershipControllerProvider);
    final tier = ui.selectedTierModel;
    final apiPkg = ui.apiPackageFor(tier.wireId);
    final wallet = ref.read(walletBalancesProvider).valueOrNull;
    final rate = wallet?.jetonTlRate ?? ui.jetonTlRate;
    final priceJeton = apiPkg?.resolvedPriceJeton(
          fallbackFromTry: tier.monthlyPriceTry,
          jetonTlRate: rate,
        ) ??
        (rate > 0
            ? (tier.monthlyPriceTry / rate).round()
            : tier.monthlyPriceTry * 2);
    final priceCfc = CurrencyUsageInfo.cfcForTl(tier.monthlyPriceTry);
    void onPurchaseDone() {
      ref.invalidate(membershipCatalogProvider);
      ref.refreshWalletCache(force: true);
      ref.invalidate(paymentRequestsNotifierProvider);
    }

    Future<bool> tryInstantPurchase({String? paymentMethod}) async {
      try {
        await ref.read(membershipRemoteProvider).purchaseMembership(
              tier.resolvedPlanId,
              paymentMethod: paymentMethod,
            );
        await ref.read(membershipControllerProvider.notifier).refresh();
        await refreshMembershipAfterPurchase(ref);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${tier.title} üyeliği aktif')),
          );
        }
        return true;
      } on ApiException catch (e) {
        if (!context.mounted) return false;
        final insufficient = e.message.contains('Yetersiz jeton') ||
            e.message.contains('Yetersiz CFC') ||
            e.message.toLowerCase().contains('insufficient');
        if (!insufficient) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
          return true;
        }
        return false;
      } catch (_) {
        return false;
      }
    }

    if (wallet != null && priceJeton > 0 && wallet.jeton >= priceJeton) {
      if (await tryInstantPurchase()) return;
    }

    final cfcBal = wallet?.cfc ?? ui.cfcBalance;
    if (cfcBal >= priceCfc && priceCfc > 0) {
      if (await tryInstantPurchase(paymentMethod: 'cfc')) return;
    }

    if (!context.mounted) return;

    List<PaymentMethodEntity> paymentMethods;
    try {
      paymentMethods = await ref.read(paymentMethodsProvider.future);
    } catch (_) {
      paymentMethods = PaymentMethodEntity.defaults;
    }
    final externalLabel = PaymentMethodsSummaryLine.externalCheckoutLabelFrom(
      paymentMethods,
    );

    final choice = await showMembershipCheckoutSheet(
      context,
      tier: tier,
      priceJeton: priceJeton,
      priceCfc: priceCfc,
      cfcBalance: cfcBal,
      externalMethodsLabel: externalLabel,
    );
    if (!context.mounted || choice == null) return;

    if (choice == MembershipCheckoutChoice.cfcPayment) {
      if (cfcBal >= priceCfc) {
        final ok = await submitMembershipCfcInstant(
          context,
          ref,
          tier: tier,
          priceCfc: priceCfc,
          onDone: onPurchaseDone,
        );
        if (ok) return;
      }
      await openMembershipCfcCheckoutFlow(
        context,
        ref,
        tier: tier,
        onDone: onPurchaseDone,
      );
      return;
    }

    final jetonPkg = JetonPackageEntity(
      id: 'membership_${tier.wireId}',
      title: '${tier.title} Üyelik · ${tier.durationLabel}',
      coins: priceJeton,
      priceTry: tier.monthlyPriceTry.toDouble(),
      badge: ui.hasActivePaidMembership ? 'Uzat' : null,
    );

    openJetonCheckoutFlow(
      context,
      ref,
      package: jetonPkg,
      priceText:
          '₺${tier.monthlyPriceTry} (${tier.monthlyTokens} jeton · ${tier.durationLabel})',
      paymentNotes:
          'Üyelik · ${tier.title} · ${tier.durationLabel} · ${tier.monthlyTokens} jeton',
      onDone: onPurchaseDone,
    );
  }
}

class _MembershipBackdrop extends StatelessWidget {
  const _MembershipBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: MembershipCatalogData.bg),
          Positioned(
            top: -80,
            right: -40,
            child: _GlowOrb(
              color: MembershipCatalogData.purple.withValues(alpha: 0.35),
              size: 260,
            ),
          ),
          Positioned(
            top: 180,
            left: -90,
            child: _GlowOrb(
              color: MembershipCatalogData.blue.withValues(alpha: 0.22),
              size: 220,
            ),
          ),
          Positioned(
            bottom: 120,
            right: -60,
            child: _GlowOrb(
              color: MembershipCatalogData.gold.withValues(alpha: 0.16),
              size: 200,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size * 0.55, spreadRadius: 8),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.06, 1.06),
          duration: 3200.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _MembershipAppBar extends StatelessWidget {
  const _MembershipAppBar({
    required this.diamondLabel,
    required this.onBack,
    required this.onAddDiamonds,
  });

  final String diamondLabel;
  final VoidCallback onBack;
  final VoidCallback onAddDiamonds;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Text(
                'Üyelikler 👑',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daha fazla ayrıcalık, daha fazla eğlence!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAddDiamonds,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: MembershipCatalogData.glassBorder,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💎', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    diamondLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          MembershipCatalogData.purple,
                          MembershipCatalogData.blue,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.08, end: 0);
  }
}

class _ExpiredMembershipBanner extends StatelessWidget {
  const _ExpiredMembershipBanner({
    required this.label,
    required this.onRenew,
  });

  final String label;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRenew,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
            color: const Color(0xFF3D2060).withValues(alpha: 0.65),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer_off_rounded,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$label süresi doldu · planı yenile',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({
    required this.label,
    required this.days,
    required this.onExtend,
  });

  final String label;
  final int days;
  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onExtend,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: MembershipCatalogData.gold.withValues(alpha: 0.65),
            ),
            color: MembershipCatalogData.gold.withValues(alpha: 0.1),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: MembershipCatalogData.gold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$label üyeliğiniz aktif · $days gün kaldı',
                  style: const TextStyle(
                    color: MembershipCatalogData.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: MembershipCatalogData.gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner({required this.onBuyTokens});

  final VoidCallback onBuyTokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: MembershipCatalogData.purple.withValues(alpha: 0.45),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MembershipCatalogData.purpleDeep.withValues(alpha: 0.55),
            MembershipCatalogData.purple.withValues(alpha: 0.28),
            const Color(0xFF1E1B4B).withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: MembershipCatalogData.purple.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFB45309)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MembershipCatalogData.gold.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Üyeliğini Yükselt, Avantajları Katla!',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Daha fazla jeton, daha fazla ayrıcalık ve özel içerikler seni bekliyor.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBuyTokens,
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFA78BFA),
                          Color(0xFF6366F1),
                        ],
                      ),
                    ),
                    child: const Text(
                      'Jeton\nSatın Al',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 160.ms, duration: 420.ms).scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
        );
  }
}

/// Geriye uyumluluk — eski route aynı sayfayı açar.
class PremiumMembershipPage extends MembershipPage {
  const PremiumMembershipPage({super.key});
}
