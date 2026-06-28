import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../providers/payment_requests_notifier.dart';
import '../providers/profile_providers.dart';
import '../widgets/jeton_payment_status_listener.dart';
import '../widgets/jeton_premium_purchase_view.dart';
import '../widgets/jeton_store_widgets.dart';

/// Jeton mağazası — Premium 2026: çift yönlü TL/jeton, hazır tutarlar, ödeme yöntemleri.
class JetonPurchasePage extends ConsumerWidget {
  const JetonPurchasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;

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
                      ref.refreshWalletCache(force: true);
                      ref.invalidate(paymentConfigProvider);
                      ref.invalidate(paymentRequestsNotifierProvider);
                      await ref.read(walletBalancesProvider.future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(0, top + 8, 0, 24),
                      children: [
                        ResponsiveConstrained(
                          child: Padding(
                            padding: ResponsiveLayout.pagePadding(context),
                            child: _JetonStoreHeader(onBack: () => context.pop()),
                          ),
                        ),
                        const JetonPremiumPurchaseView(),
                      ],
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
        const SizedBox(height: 12),
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
        const SizedBox(height: 4),
        Text(
          'İstediğiniz tutarı girin — jeton otomatik hesaplanır',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: context.colors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}
