import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/discover/discover_glass_card.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../wallet/presentation/widgets/wallet_balance_header.dart';
import '../../domain/membership_package_entity.dart';

final membershipCatalogProvider =
    FutureProvider.autoDispose<MembershipCatalogEntity>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.safeGet<Map<String, dynamic>>(
    ApiEndpoints.membershipPackages,
  );
  final raw = res.data;
  final data = raw is Map ? asJsonMap(raw) : <String, dynamic>{};
  if (data['error'] != null) {
    throw ApiException(data['error'].toString());
  }
  return MembershipCatalogEntity.fromJson(data);
});

/// Gold üyelik sayfası — mockup: Basic / Premium / Gold / Diamond.
class PremiumMembershipPage extends ConsumerWidget {
  const PremiumMembershipPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(membershipCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: catalog.when(
          loading: () => const Center(child: DiscoverAccentLoader()),
          error: (e, _) => DiscoverSubPage(
            title: 'Premium Üyelik',
            subtitle: ApiException.userMessage(e),
            body: Center(child: Text(ApiException.userMessage(e))),
          ),
          data: (cat) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _HeroHeader(catalog: cat),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = cat.packages[i];
                      return _TierCard(
                        package: p,
                        onBuy: () => _purchase(context, ref, p),
                      );
                    },
                    childCount: cat.packages.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: const Text(
                    'Özellikler',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _FeaturesRow(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                  child: _ComparisonTable(packages: cat.packages),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    MembershipPackageEntity pkg,
  ) async {
    try {
      await ref.read(dioProvider).safePost<Map<String, dynamic>>(
        ApiEndpoints.membershipPurchase,
        data: {'tierId': pkg.id},
      );
      ref.invalidate(membershipCatalogProvider);
      ref.invalidate(walletBalancesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pkg.isActive
                  ? '${pkg.title} üyeliğiniz uzatıldı'
                  : '${pkg.title} üyeliği aktif',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.catalog});

  final MembershipCatalogEntity catalog;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFD54F).withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 56,
            color: Color(0xFFFFD54F),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Premium Üyelik',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sınırsız erişim, özel ayrıcalıklar ve VIP deneyim',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.95),
            fontSize: 14,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            _FeaturePill(icon: Icons.star_rounded, label: 'Bonus Jeton'),
            _FeaturePill(icon: Icons.diamond_rounded, label: 'Özel Rozet'),
            _FeaturePill(icon: Icons.headset_mic_rounded, label: 'Öncelikli Destek'),
            _FeaturePill(icon: Icons.auto_awesome, label: 'İndirimli Fal'),
          ],
        ),
        const SizedBox(height: 20),
        WalletBalanceHeader(
          jeton: catalog.jetonBalance,
          cfc: catalog.cfcBalance,
          membership: catalog.currentMembership,
          daysRemaining: catalog.daysRemaining,
          showQuickLinks: false,
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentCyan),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.package, required this.onBuy});

  final MembershipPackageEntity package;
  final VoidCallback onBuy;

  Color get _accent => switch (package.id) {
        'premium' => const Color(0xFF5B8CFF),
        'gold' => const Color(0xFFFFD54F),
        'diamond' => AppColors.accentPink,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final active = package.isActive && (package.daysRemaining ?? 0) > 0;

    return DiscoverGlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: active ? _accent.withValues(alpha: 0.7) : _accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                package.isDiamond
                    ? Icons.diamond_rounded
                    : package.isGold
                        ? Icons.workspace_premium_rounded
                        : Icons.shield_rounded,
                color: _accent,
                size: 22,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _accent.withValues(alpha: 0.2),
                ),
                child: const Text('VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            package.title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: _accent,
            ),
          ),
          Text(
            '${package.durationDays} gün',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const Spacer(),
          Text(
            '${package.priceJeton} Jeton',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          if (active) ...[
            const SizedBox(height: 6),
            Text(
              '${package.daysRemaining ?? 0} gün kaldı',
              style: TextStyle(fontSize: 11, color: _accent.withValues(alpha: 0.95)),
            ),
          ],
          const SizedBox(height: 10),
          FilledButton(
            onPressed: onBuy,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: package.id == 'gold' ? Colors.black87 : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              active ? 'Uzat' : 'Satın Al',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeatureTile(
          icon: Icons.star_rounded,
          title: 'Bonus Jeton',
          subtitle: 'Her paketle birlikte bonus jeton kazanın',
        ),
        const SizedBox(height: 10),
        _FeatureTile(
          icon: Icons.diamond_rounded,
          title: 'Özel Rozet',
          subtitle: 'Özel üyelik rozeti ile farkınızı gösterin',
        ),
        const SizedBox(height: 10),
        _FeatureTile(
          icon: Icons.headset_mic_rounded,
          title: 'Öncelikli Destek',
          subtitle: '7/24 öncelikli destek hizmetinden faydalanın',
        ),
        const SizedBox(height: 10),
        _FeatureTile(
          icon: Icons.auto_awesome,
          title: 'İndirimli Fal',
          subtitle: 'Fal bakımlarında özel indirimlerden yararlanın',
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DiscoverGlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentCyan, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.packages});

  final List<MembershipPackageEntity> packages;

  @override
  Widget build(BuildContext context) {
    final cols = packages.isNotEmpty
        ? packages
        : [
            const MembershipPackageEntity(
              id: 'basic',
              title: 'Basic',
              durationDays: 30,
              priceJeton: 100,
              bonusJeton: 100,
              falDiscountPercent: 10,
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Paket Karşılaştırması',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.accentPurple.withValues(alpha: 0.2),
            ),
            columns: [
              const DataColumn(label: Text('Özellikler', style: TextStyle(fontWeight: FontWeight.w800))),
              ...cols.map((p) => DataColumn(label: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w800)))),
            ],
            rows: [
              _row('Süre', cols.map((p) => '${p.durationDays} Gün').toList()),
              _row('VIP Rozet', cols.map((_) => '✓').toList()),
              _row('Bonus Jeton', cols.map((p) => '${p.bonusJeton}').toList()),
              _row('Öncelikli Destek', cols.map((_) => '✓').toList()),
              _row('İndirimli Fal', cols.map((p) => '%${p.falDiscountPercent}').toList()),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _row(String label, List<String> values) {
    return DataRow(
      cells: [
        DataCell(Text(label, style: const TextStyle(fontSize: 12))),
        ...values.map((v) => DataCell(Text(v, style: const TextStyle(fontSize: 12)))),
      ],
    );
  }
}
