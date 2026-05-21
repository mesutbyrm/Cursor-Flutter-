import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../../../../core/widgets/dual_balance_chips.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../providers/profile_providers.dart';
import '../widgets/jeton_checkout_flow.dart';

/// Ana sayfadan veya profilden açılır; paketleri `/api/jeton` üzerinden okur.
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

  String _formatPrice(JetonPackageEntity p) {
    if (p.priceLabel != null && p.priceLabel!.trim().isNotEmpty) {
      return p.priceLabel!.trim();
    }
    if (p.priceTry != null) {
      return NumberFormat.currency(
        locale: 'tr_TR',
        symbol: '₺',
        decimalDigits: 2,
      ).format(p.priceTry);
    }
    return '—';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(jetonPackagesProvider);
    final wallet = ref.watch(walletBalancesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFFD54F), AppTheme.accentSecondary],
          ).createShader(b),
          child: const Text(
            'Jeton yükle',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _JetonBackdrop(),
          RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () async {
              ref.invalidate(jetonPackagesProvider);
              ref.invalidate(walletBalancesProvider);
              await ref.read(jetonPackagesProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
                    16,
                    32,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      GlowPanel(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on_rounded,
                                color: Color(0xFFFFD54F), size: 40),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mevcut bakiye',
                                    style: TextStyle(
                                      color: AppTheme.muted
                                          .withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  wallet.when(
                                    data: (b) => DualBalanceChips(
                                      jeton: b.jeton,
                                      cfc: b.cfc,
                                    ),
                                    loading: () => const Text('…'),
                                    error: (e, _) => Text(
                                      ApiException.userMessage(e),
                                      style: const TextStyle(
                                        color: AppTheme.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'WhatsApp, Papara veya Havale/EFT ile ödeme yapın. '
                        'Talebiniz admin ve site bildirim paneline düşer — web’e gerek yok.',
                        style: TextStyle(
                          color: AppTheme.muted.withValues(alpha: 0.95),
                          height: 1.35,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Paketler',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ]),
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
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 48,
                              color: AppTheme.muted.withValues(alpha: 0.8)),
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
                  data: (list) {
                    if (list.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 48,
                                  color:
                                      AppTheme.muted.withValues(alpha: 0.8)),
                              const SizedBox(height: 12),
                              Text(
                                'Paket listesi alınamadı. API ve oturum ayarlarını kontrol edin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      AppTheme.muted.withValues(alpha: 0.95),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final p = list[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _JetonPackageCard(
                                package: p,
                                priceText: _formatPrice(p),
                                onBuy: () => _openCheckout(
                                  context,
                                  ref,
                                  p,
                                  _formatPrice(p),
                                ),
                              ),
                            );
                          },
                          childCount: list.length,
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
}

class _JetonBackdrop extends StatelessWidget {
  const _JetonBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.background,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A1C10),
            AppTheme.background,
            const Color(0xFF101820),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.4),
            radius: 1.1,
            colors: [
              const Color(0xFFFFD54F).withValues(alpha: 0.12),
              Colors.transparent,
            ],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _JetonPackageCard extends StatelessWidget {
  const _JetonPackageCard({
    required this.package,
    required this.priceText,
    required this.onBuy,
  });

  final JetonPackageEntity package;
  final String priceText;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return GlowPanel(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.35),
                  AppTheme.accentSecondary.withValues(alpha: 0.25),
                ],
              ),
            ),
            child: Text(
              package.coins > 0 ? '${package.coins}' : '★',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (package.badge != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    package.badge!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.accentSecondary.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  priceText,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.muted.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onBuy,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Satın al'),
          ),
        ],
      ),
    );
  }
}
