import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../../core/util/json_util.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/membership_catalog_fallback.dart';
import '../../domain/membership_package_entity.dart';
import '../widgets/premium_membership_widgets.dart';

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
  var catalog = MembershipCatalogEntity.fromJson(data);
  if (catalog.packages.isEmpty) {
    catalog = MembershipCatalogEntity(
      packages: fallbackMembershipPackages(
        currentMembership: catalog.currentMembership,
        catalogDaysRemaining: catalog.daysRemaining,
      ),
      currentMembership: catalog.currentMembership,
      jetonBalance: catalog.jetonBalance,
      cfcBalance: catalog.cfcBalance,
      daysRemaining: catalog.daysRemaining,
    );
  }
  return catalog;
});

/// Premium üyelik — mockup: özellik grid, Gold durum, dikey paket kartları.
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
          error: (e, _) => Center(
            child: Padding(
              padding: ResponsiveLayout.pagePadding(context),
              child: Text(ApiException.userMessage(e), textAlign: TextAlign.center),
            ),
          ),
          data: (cat) => RefreshIndicator(
            color: AppColors.accentPurple,
            onRefresh: () async {
              ref.invalidate(membershipCatalogProvider);
              ref.invalidate(walletBalancesProvider);
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
                        ),
                        const SizedBox(height: 20),
                        const PremiumFeatureGrid(),
                        const SizedBox(height: 20),
                        if (_hasActiveMembership(cat)) ...[
                          PremiumActiveMembershipCard(
                            tierLabel: _activeTierLabel(cat),
                            daysRemaining:
                                cat.daysRemaining ?? cat.activePackage?.daysRemaining ?? 0,
                            onExtend: () => _purchase(
                              context,
                              ref,
                              cat.packages.firstWhere(
                                (p) => p.id == cat.currentMembership.toLowerCase(),
                                orElse: () => cat.packages.firstWhere(
                                  (p) => p.isActive,
                                  orElse: () => cat.packages.first,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        PremiumBalanceLines(
                          jeton: cat.jetonBalance,
                          cfc: cat.cfcBalance,
                        ),
                        const SizedBox(height: 24),
                        ...cat.packages.map(
                          (p) => PremiumTierCard(
                            package: p,
                            onBuy: () => _purchase(context, ref, p),
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }
}
