import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/admin_providers.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_user_picker.dart';
import '../widgets/admin_credit_sheet.dart';
import '../widgets/admin_membership_sheet.dart';
import '../widgets/admin_stats_list_sheet.dart';

/// Admin profil paneli — web admin ile aynı yetenekler.
class AdminPanelPage extends ConsumerStatefulWidget {
  const AdminPanelPage({super.key});

  @override
  ConsumerState<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends ConsumerState<AdminPanelPage> {
  void _refresh() {
    ref.invalidate(adminPanelBadgeCountsProvider);
    ref.invalidate(adminPaymentRequestsProvider);
    ref.invalidate(adminPaymentNotificationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Bu alan yalnızca admin veya yönetici hesapları içindir.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final badgesAsync = ref.watch(adminPanelBadgeCountsProvider);
    final badges = badgesAsync.valueOrNull ?? const AdminPanelBadges();
    final badgesLoading = badgesAsync.isLoading && !badgesAsync.hasValue;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: DiscoverTabHeader(
                      title: 'Admin Paneli',
                      subtitle: 'Ödeme, kullanıcı, jeton/CFC, üyelik',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refresh,
                  ),
                  if (badgesLoading)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppThemeColors.accentPink,
                onRefresh: () async => _refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    if (badgesAsync.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'İstatistikler yüklenemedi — menü kullanılabilir.',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceMuted,
                          ),
                        ),
                      ),
                    _SectionTitle('Bekleyen işlemler'),
                    _ActionGrid(items: [
                      _PanelItem(
                        icon: Icons.payments_rounded,
                        label: 'Ödeme talepleri',
                        badge: badges.pendingPayments,
                        onTap: () => context.push('/admin'),
                      ),
                      _PanelItem(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Para çekme talepleri',
                        badge: badges.pendingWithdrawals,
                        onTap: () => context.push('/admin'),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _SectionTitle('Bugün & istatistikler'),
                    _ActionGrid(items: [
                      _PanelItem(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Bugün üye olanlar',
                        badge: badges.todayMembers,
                        onTap: () => _openStats(context, AdminStatsKind.todayMembers),
                      ),
                      _PanelItem(
                        icon: Icons.monetization_on_outlined,
                        label: 'Bugün jeton alanlar',
                        badge: badges.todayJetonBuyers,
                        onTap: () => _openStats(context, AdminStatsKind.todayJetonBuyers),
                      ),
                      _PanelItem(
                        icon: Icons.meeting_room_outlined,
                        label: 'Oda açanlar',
                        badge: badges.todayRoomOpeners,
                        onTap: () => _openStats(context, AdminStatsKind.roomOpeners),
                      ),
                      _PanelItem(
                        icon: Icons.live_tv_rounded,
                        label: 'Yayın yapanlar',
                        badge: badges.todayBroadcasters,
                        onTap: () => _openStats(context, AdminStatsKind.broadcasters),
                      ),
                      _PanelItem(
                        icon: Icons.emoji_events_outlined,
                        label: 'En çok kazanan',
                        badge: badges.topEarners,
                        onTap: () => _openStats(context, AdminStatsKind.topEarners),
                      ),
                      _PanelItem(
                        icon: Icons.card_giftcard_rounded,
                        label: 'En çok hediye atanlar',
                        badge: badges.topGiftSenders,
                        onTap: () => _openStats(context, AdminStatsKind.topGiftSenders),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _SectionTitle('Manuel işlemler'),
                    _ActionGrid(items: [
                      _PanelItem(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Jeton yükle / çıkar',
                        onTap: () => _openCredit(context, AdminCreditKind.jeton),
                      ),
                      _PanelItem(
                        icon: Icons.toll_outlined,
                        label: 'CFC yükle / çıkar',
                        onTap: () => _openCredit(context, AdminCreditKind.cfc),
                      ),
                      _PanelItem(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Gold / Premium / Diamond',
                        onTap: () => _openMembership(context),
                      ),
                      _PanelItem(
                        icon: Icons.manage_accounts_rounded,
                        label: 'Kullanıcı yönetimi',
                        onTap: () => context.push('/admin/users'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCredit(BuildContext context, AdminCreditKind kind) async {
    final user = await AdminUserPicker.show(context, ref);
    if (user == null || !context.mounted) return;
    await AdminCreditSheet.show(
      context,
      ref: ref,
      user: user,
      kind: kind,
    );
    _refresh();
  }

  Future<void> _openMembership(BuildContext context) async {
    final user = await AdminUserPicker.show(context, ref);
    if (user == null || !context.mounted) return;
    await AdminMembershipSheet.show(
      context,
      ref: ref,
      user: user,
    );
    _refresh();
  }

  Future<void> _openStats(BuildContext context, AdminStatsKind kind) async {
    await AdminStatsListSheet.show(context, ref: ref, kind: kind);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}

class _PanelItem {
  const _PanelItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.items});

  final List<_PanelItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return DiscoverGlassCard(
          onTap: item.onTap,
          padding: const EdgeInsets.all(14),
          borderColor: AppThemeColors.accentPink.withValues(alpha: 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.icon, color: AppThemeColors.accentCyan, size: 22),
                  const Spacer(),
                  if (item.badge > 0)
                    _Badge(count: item.badge),
                ],
              ),
              const Spacer(),
              Text(
                item.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.25,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppThemeColors.liveRed,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum AdminCreditKind { jeton, cfc }

enum AdminStatsKind {
  todayMembers,
  todayJetonBuyers,
  roomOpeners,
  broadcasters,
  topEarners,
  topGiftSenders,
}
