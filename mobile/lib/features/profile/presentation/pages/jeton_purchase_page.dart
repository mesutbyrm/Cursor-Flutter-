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
  }

  List<JetonPackageEntity> _packageList(AsyncValue<List<JetonPackageEntity>> packages) {
    final remote = packages.valueOrNull;
    if (remote == null || remote.isEmpty) return kFallbackJetonPackages;
    return remote;
  }

  void _openPaymentNotifyNow() {
    final list = _packageList(ref.read(jetonPackagesProvider));
    final selected = _resolveSelected(list);
    unawaited(
      openJetonPaymentNotifySheet(
        context,
        ref,
        package: selected,
        priceTry: selected?.priceTry,
        onDone: () {
          ref.invalidate(walletBalancesProvider);
          ref.invalidate(jetonPackagesProvider);
        },
      ),
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
    final items = _packageList(packages);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: JetonPaymentStatusListener(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const JetonStoreBackdrop(),
            Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: AppThemeColors.accentPurple,
                    onRefresh: () async {
                      ref.invalidate(jetonPackagesProvider);
                      ref.invalidate(walletBalancesProvider);
                      await ref.read(jetonPackagesProvider.future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        0,
                        top + 8,
                        0,
                        12,
                      ),
                      children: [
                        ResponsiveConstrained(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                          onTap: () => context
                                              .push('/premium-membership'),
                                        ),
                                      ],
                                    ],
                                  ),
                                  loading: () => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  error: (e, _) => Text(
                                    ApiException.userMessage(e),
                                    style: TextStyle(
                                      color: context.colors.onSurfaceMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (packages.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        if (packages.hasError)
                          Padding(
                            padding: ResponsiveLayout.pagePadding(context),
                            child: Text(
                              ApiException.userMessage(packages.error!),
                              style: TextStyle(
                                color: context.colors.onSurfaceMuted,
                              ),
                            ),
                          ),
                        _JetonPackagesBody(
                          list: items,
                          wallet: wallet,
                          selectedId: _selectedPackageId,
                          onTapPackage: _tapPackage,
                          onOpenCheckout: _openCheckout,
                        ),
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0618).withValues(alpha: 0.92),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottom),
                    child: _PaidNotifyFooter(
                      hasSelection: _selectedPackageId != null,
                      onNotify: _openPaymentNotifyNow,
                    ),
                  ),
                ),
              ],
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
      alignment: Alignment.center,
      child: Padding(
        padding: ResponsiveLayout.pagePadding(context, top: 10, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasSelection
                  ? 'Ödemenizi yaptıktan sonra bildirim gönderin'
                  : 'Paket seçin veya özel miktar belirleyin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onNotify,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          color:
                              const Color(0xFF22C55E).withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF22C55E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ödemeyi Yaptım, Bildir',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            Text(
                              'Ödeme bildirimi formunu hemen aç',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
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

class _JetonPackagesBody extends StatelessWidget {
  const _JetonPackagesBody({
    required this.list,
    required this.wallet,
    required this.onTapPackage,
    required this.onOpenCheckout,
    this.selectedId,
  });

  final List<JetonPackageEntity> list;
  final AsyncValue<WalletBalances> wallet;
  final String? selectedId;
  final void Function(JetonPackageEntity package) onTapPackage;
  final Future<void> Function(JetonPackageEntity package, String priceText)
      onOpenCheckout;

  @override
  Widget build(BuildContext context) {
    final grid = jetonGridPackages(list);
    final hero = jetonHeroPackage(list);
    final rate = wallet.valueOrNull?.jetonTlRate ?? kDefaultJetonTlRate;

    return ResponsiveConstrained(
      child: Padding(
        padding: ResponsiveLayout.pagePadding(context, top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (grid.isNotEmpty)
              _ResponsivePackageGrid(
                packages: grid,
                selectedId: selectedId,
                onTap: onTapPackage,
              ),
            if (hero != null) ...[
              const SizedBox(height: 4),
              JetonPackageTile(
                package: hero,
                priceText: formatJetonPrice(hero),
                fullWidth: true,
                selected: hero.id == selectedId,
                onTap: () => onTapPackage(hero),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Paket seçin veya özel miktar belirleyin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            JetonCustomAmountSection(
              tlRate: rate,
              onPurchase: (p, price) {
                onTapPackage(p);
                unawaited(onOpenCheckout(p, price));
              },
            ),
            if (selectedId != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final selected = list.where((p) => p.id == selectedId).firstOrNull;
                  if (selected != null) {
                    unawaited(
                      onOpenCheckout(selected, formatJetonPrice(selected)),
                    );
                  }
                },
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Ödeme yöntemlerini görüntüle'),
              ),
            ],
          ],
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
