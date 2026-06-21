import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../data/jeton_packages_catalog.dart';
import '../../data/jeton_purchase_prefs.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../providers/profile_providers.dart';
import '../widgets/currency_usage_card.dart';
import '../widgets/jeton_checkout_flow.dart';
import '../widgets/jeton_payment_notify_sheet.dart';
import '../widgets/jeton_payment_status_listener.dart';
import '../widgets/jeton_store_widgets.dart';

/// Jeton mağazası — paket seçimi, son paket hatırlama, ödeme bildirimi.
class JetonPurchasePage extends ConsumerStatefulWidget {
  const JetonPurchasePage({super.key});

  @override
  ConsumerState<JetonPurchasePage> createState() => _JetonPurchasePageState();
}

class _JetonPurchasePageState extends ConsumerState<JetonPurchasePage> {
  final _prefs = JetonPurchasePrefs();
  String? _selectedPackageId;

  @override
  void initState() {
    super.initState();
    _loadLastPackage();
  }

  Future<void> _loadLastPackage() async {
    final id = await _prefs.loadLastPackageId();
    if (!mounted || id == null) return;
    setState(() => _selectedPackageId = id);
  }

  void _selectPackage(JetonPackageEntity package) {
    setState(() => _selectedPackageId = package.id);
  }

  void _tapPackage(JetonPackageEntity package) {
    _selectPackage(package);
    unawaited(_prefs.saveLastPackageId(package.id));
    unawaited(
      _openCheckout(package, formatJetonPrice(package)),
    );
  }

  Future<void> _openPaymentNotify({JetonPackageEntity? package}) async {
    final items = ref.read(jetonPackagesProvider).valueOrNull;
    final list = (items == null || items.isEmpty) ? kFallbackJetonPackages : items;
    final selected = package ?? _resolveSelected(list);
    await openJetonPaymentNotifySheet(
      context,
      ref,
      package: selected,
      priceTry: selected?.priceTry,
      onDone: () {
        ref.invalidate(walletBalancesProvider);
        ref.invalidate(jetonPackagesProvider);
      },
    );
  }

  Future<void> _openCheckout(JetonPackageEntity package, String priceText) async {
    await _prefs.saveLastPackageId(package.id);
    if (!mounted) return;
    openJetonCheckoutFlow(
      context,
      ref,
      package: package,
      priceText: priceText,
      onDone: () {
        ref.invalidate(walletBalancesProvider);
        ref.invalidate(jetonPackagesProvider);
        setState(() => _selectedPackageId = package.id);
      },
    );
  }

  JetonPackageEntity? _resolveSelected(List<JetonPackageEntity> list) {
    final id = _selectedPackageId;
    if (id == null) return null;
    for (final p in list) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final packages = ref.watch(jetonPackagesProvider);
    final wallet = ref.watch(walletBalancesProvider);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: JetonPaymentStatusListener(
        child: Stack(
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
                          const SizedBox(height: 16),
                          const CurrencyUsageCard.jeton(),
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
                              style: TextStyle(color: context.colors.onSurfaceMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                packages.when(
                  loading: () => SliverMainAxisGroup(
                    slivers: [
                      _JetonPackagesContent(
                        pageContext: context,
                        list: kFallbackJetonPackages,
                        wallet: wallet,
                        selectedId: _selectedPackageId,
                        onSelect: _selectPackage,
                        onCheckout: (p, price) => _openCheckout(p, price),
                        onTapPackage: _tapPackage,
                        isRefreshing: true,
                      ),
                      SliverToBoxAdapter(
                        child: _PaidNotifyFooter(
                          hasSelection: _selectedPackageId != null,
                          onNotify: () => _openPaymentNotify(),
                        ),
                      ),
                    ],
                  ),
                  error: (e, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: ResponsiveConstrained(
                      child: Padding(
                        padding: ResponsiveLayout.pagePadding(context),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 48,
                              color: context.colors.onSurfaceMuted
                                  .withValues(alpha: 0.8),
                            ),
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
                    final items =
                        list.isEmpty ? kFallbackJetonPackages : list;
                    final selected = _resolveSelected(items);
                    return SliverMainAxisGroup(
                      slivers: [
                        _JetonPackagesContent(
                          pageContext: context,
                          list: items,
                          wallet: wallet,
                          selectedId: _selectedPackageId,
                          onSelect: _selectPackage,
                          onCheckout: (p, price) => _openCheckout(p, price),
                          onTapPackage: _tapPackage,
                        ),
                        SliverToBoxAdapter(
                          child: _PaidNotifyFooter(
                            hasSelection: selected != null,
                            onNotify: () =>
                                _openPaymentNotify(package: selected),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + 88,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  static bool _isGoldMember(String? membership, int? days) {
    if (membership?.toLowerCase() != 'gold') return false;
    return (days ?? 0) > 0;
  }
}

class _PaidNotifyFooter extends StatelessWidget {
  const _PaidNotifyFooter({
    required this.hasSelection,
    required this.onNotify,
  });

  final bool hasSelection;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    return ResponsiveConstrained(
      child: Padding(
        padding: ResponsiveLayout.pagePadding(context, top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasSelection
                        ? 'Ödemenizi yaptıktan sonra bildirim gönderin'
                        : 'Paket seçin veya özel miktar belirleyerek ödeme yöntemlerini görüntüleyin',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onNotify,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF0D2818).withValues(alpha: 0.65),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.75),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF22C55E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ödeme Yaptım, Bildir',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            Text(
                              'Ödemenizi yaptıktan sonra buradan bildirim gönderin',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.colors.onSurfaceMuted
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: const Color(0xFF22C55E).withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            color: AppThemeColors.coinGold.withValues(alpha: 0.2),
            border: Border.all(
              color: AppThemeColors.coinGold.withValues(alpha: 0.55),
              width: 2,
            ),
            boxShadow:
                AppThemeColors.glowShadow(AppThemeColors.coinGold, blur: 18),
          ),
          child: const Icon(
            Icons.monetization_on_rounded,
            color: AppThemeColors.coinGold,
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
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
    required this.list,
    required this.wallet,
    required this.onSelect,
    required this.onCheckout,
    required this.onTapPackage,
    this.selectedId,
    this.isRefreshing = false,
  });

  final BuildContext pageContext;
  final List<JetonPackageEntity> list;
  final AsyncValue<WalletBalances> wallet;
  final String? selectedId;
  final void Function(JetonPackageEntity package) onSelect;
  final void Function(JetonPackageEntity package, String priceText) onCheckout;
  final void Function(JetonPackageEntity package) onTapPackage;
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
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (grid.isNotEmpty)
                _ResponsivePackageGrid(
                  packages: grid,
                  selectedId: selectedId,
                  onTap: onTapPackage,
                ),
              if (hero != null) ...[
                JetonPackageTile(
                  package: hero,
                  priceText: formatJetonPrice(hero),
                  fullWidth: true,
                  selected: hero.id == selectedId,
                  onTap: () => onTapPackage(hero),
                ),
              ],
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '👆 Paket seçin veya özel miktar belirleyerek ödeme yöntemlerini görüntüleyin',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Theme.of(pageContext)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
                ),
              ),
              JetonCustomAmountSection(
                tlRate: rate,
                onPurchase: (p, price) {
                  onSelect(p);
                  onTapPackage(p);
                  onCheckout(p, price);
                },
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
    this.selectedId,
  });

  final List<JetonPackageEntity> packages;
  final void Function(JetonPackageEntity) onTap;
  final String? selectedId;

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
                selected: p.id == selectedId,
                onTap: () => onTap(p),
              );
            },
          ),
        );
      },
    );
  }
}
