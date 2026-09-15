import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../gifts/domain/gift_collection.dart';
import '../../domain/admin_payment_review.dart';
import '../../domain/admin_user_detail.dart';
import '../../domain/admin_user_permissions.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/admin_user_detail_provider.dart';
import '../providers/staff_access_provider.dart';
import '../pages/admin_panel_page.dart';
import '../widgets/admin_credit_sheet.dart';
import '../widgets/admin_membership_sheet.dart';
import '../widgets/admin_user_manage_sheet.dart';
import '../../domain/admin_user_extended_data.dart';
import '../widgets/admin_role_permissions_matrix.dart';
import '../widgets/admin_user_command_actions.dart';
import '../widgets/admin_user_finance_ledger_section.dart';
import '../widgets/admin_discovery_permissions_card.dart';
import '../widgets/admin_user_presence_strip.dart';
import '../widgets/admin_hub_platform_social.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import 'admin_user_command_center_extended_tabs.dart';

/// Tam kullanıcı komuta merkezi — özet, finans, hediye, yetki, aktivite.
class AdminUserCommandCenterPage extends ConsumerStatefulWidget {
  const AdminUserCommandCenterPage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserCommandCenterPage> createState() =>
      _AdminUserCommandCenterPageState();
}

class _AdminUserCommandCenterPageState
    extends ConsumerState<AdminUserCommandCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 10, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(adminUserDetailProvider(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!AdminUserPermissions.canViewOverview(access)) {
      return _locked(context);
    }

    final bundleAsync = ref.watch(adminUserDetailProvider(widget.userId));

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
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: bundleAsync.when(
                      loading: () => const DiscoverTabHeader(
                        title: 'Kullanıcı',
                        subtitle: 'Yükleniyor…',
                      ),
                      error: (e, _) => DiscoverTabHeader(
                        title: 'Kullanıcı',
                        subtitle: ApiException.userMessage(e),
                      ),
                      data: (b) => DiscoverTabHeader(
                        title: b.detail.displayName ?? b.detail.label,
                        subtitle: b.detail.username != null
                            ? '@${b.detail.username}'
                            : widget.userId,
                      ),
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              indicatorColor: PlatformSocialPalette.accent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Özet'),
                Tab(text: 'Finans'),
                Tab(text: 'Hediyeler'),
                Tab(text: 'Yayın/Oda'),
                Tab(text: 'VIP'),
                Tab(text: 'Ajans'),
                Tab(text: 'Yetkiler'),
                Tab(text: 'Mod.'),
                Tab(text: 'Aktivite'),
                Tab(text: 'Rapor'),
              ],
            ),
            bundleAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (bundle) => _AdminQuickActionsRow(
                bundle: bundle,
                access: access,
                onRefresh: _refresh,
              ),
            ),
            Expanded(
              child: bundleAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppThemeColors.accentPink,
                  ),
                ),
                error: (e, _) => Center(
                  child: DiscoverEmptyState(
                    icon: Icons.error_outline,
                    message: ApiException.userMessage(e),
                    actionLabel: 'Tekrar',
                    action: _refresh,
                  ),
                ),
                data: (bundle) {
                  if (bundle.loadWarnings.isNotEmpty) {
                    return Column(
                      children: [
                        _WarningsStrip(warnings: bundle.loadWarnings),
                        Expanded(
                          child: _TabBody(
                            tabs: _tabs,
                            bundle: bundle,
                            access: access,
                            onRefresh: _refresh,
                          ),
                        ),
                      ],
                    );
                  }
                  return _TabBody(
                    tabs: _tabs,
                    bundle: bundle,
                    access: access,
                    onRefresh: _refresh,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locked(BuildContext context) {
    return Scaffold(
      body: DiscoverBackground(
        child: Center(
          child: DiscoverEmptyState(
            icon: Icons.lock_outline,
            message: 'Kullanıcı detayı için yetkiniz yok.',
            actionLabel: 'Geri',
            action: () => context.pop(),
          ),
        ),
      ),
    );
  }
}

class _WarningsStrip extends StatelessWidget {
  const _WarningsStrip({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: PlatformSocialGlassCard(
        padding: const EdgeInsets.all(12),
        gradient: LinearGradient(
          colors: [
            PlatformSocialPalette.gold.withValues(alpha: 0.15),
            PlatformSocialPalette.card.withValues(alpha: 0.9),
          ],
        ),
        child: Text(
          warnings.join(' · '),
          style: const TextStyle(fontSize: 11, height: 1.35),
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.tabs,
    required this.bundle,
    required this.access,
    required this.onRefresh,
  });

  final TabController tabs;
  final AdminUserBundle bundle;
  final StaffAccess access;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final d = bundle.detail;
    return TabBarView(
      controller: tabs,
      children: [
        _OverviewTab(detail: d, access: access),
        _FinanceTab(
          detail: d,
          history: bundle.financeHistory,
          pendingPayments: bundle.pendingPayments,
          access: access,
          onRefresh: onRefresh,
        ),
        _GiftsTab(
          detail: d,
          collection: bundle.giftCollection,
          album: bundle.giftAlbum,
          ledger: bundle.giftLedger,
          access: access,
        ),
        _BroadcastTab(
          detail: d,
          streamHistory: bundle.streamHistory,
          roomHistory: bundle.roomHistory,
          access: access,
          onRefresh: onRefresh,
        ),
        AdminUserVipTab(detail: d),
        AdminUserAgencyTab(userId: d.userId),
        _PermissionsTab(
          detail: d,
          access: access,
          liveTeller: bundle.liveTeller,
          pkBanned: bundle.pkBanned,
          animationSlots: bundle.siteAnimationSlots,
          onSaved: onRefresh,
        ),
        AdminUserModerationTab(userId: d.userId, detail: d),
        AdminUserActivityTab(
          userId: d.userId,
          fallback: bundle.activities,
          access: access,
        ),
        AdminUserReportsTab(userId: d.userId),
      ],
    );
  }
}

class _AdminQuickActionsRow extends ConsumerWidget {
  const _AdminQuickActionsRow({
    required this.bundle,
    required this.access,
    required this.onRefresh,
  });

  final AdminUserBundle bundle;
  final StaffAccess access;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = bundle.detail;
    return AdminUserQuickActionBar(
      access: access,
      onJeton: () async {
        await AdminCreditSheet.show(
          context,
          ref: ref,
          user: d.raw,
          kind: AdminCreditKind.jeton,
        );
        onRefresh();
      },
      onVip: () async {
        await AdminMembershipSheet.show(context, ref: ref, user: d.raw);
        onRefresh();
      },
      onBan: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yetkiler sekmesinden ban/askı')),
        );
      },
      onPsychic: () {
        AdminUserCommandActions.showPsychicSheet(
          context,
          ref,
          userId: d.userId,
          displayName: d.displayName ?? d.label,
          teller: bundle.liveTeller,
          onDone: onRefresh,
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.detail, required this.access});

  final AdminUserDetail detail;
  final StaffAccess access;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PlatformSocialGlassCard(
          gradient: PlatformSocialPalette.heroGradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: detail.avatarUrl != null &&
                            detail.avatarUrl!.isNotEmpty
                        ? canlifalImageProvider(detail.avatarUrl!)
                        : null,
                    child: detail.avatarUrl == null || detail.avatarUrl!.isEmpty
                        ? Text(
                            (detail.displayName?.isNotEmpty == true
                                    ? detail.displayName![0]
                                    : '?')
                                .toUpperCase(),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.displayName ?? detail.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        if (detail.username != null)
                          Text(
                            '@${detail.username}',
                            style: const TextStyle(
                              color: PlatformSocialPalette.textMuted,
                            ),
                          ),
                        Text(
                          'Rol: ${detail.role} · ${detail.membership}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (detail.isOnline)
                    const PlatformSocialStatusPill(
                      label: 'Online',
                      tone: PlatformSocialPillTone.success,
                      icon: Icons.circle,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AdminUserPresenceStrip(userId: detail.userId),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const PlatformSocialSectionTitle('Özet istatistikler'),
        _StatGrid(items: [
          _Stat('Jeton', '${detail.jeton}'),
          _Stat('CFC', '${detail.cfc}'),
          _Stat('Canlı yayın', '${detail.liveStreamCount}'),
          _Stat('Sesli oda', '${detail.voiceRoomCount}'),
          _Stat('Hediye aldı', '${detail.giftsReceivedCount}'),
          _Stat('Hediye attı', '${detail.giftsSentCount}'),
          _Stat('Jeton harcama', '${detail.totalSpentJeton}'),
          _Stat('Reklam izleme', '${detail.adsWatched}'),
          _Stat('Takipçi', '${detail.followers}'),
          _Stat('Profil görüntüleme', '${detail.profileViews}'),
        ]),
        const SizedBox(height: 16),
        const PlatformSocialSectionTitle('Profil bilgisi'),
        PlatformSocialInfoRow(
          label: 'Üyelik süresi',
          value: formatMembershipTenure(detail.memberSince),
        ),
        PlatformSocialInfoRow(
          label: 'Son online',
          value: formatLastOnline(
            detail.lastSeenAt,
            isOnline: detail.isOnline,
          ),
        ),
        if (detail.memberSince != null)
          PlatformSocialInfoRow(
            label: 'Kayıt tarihi',
            value: DateFormat('dd.MM.yyyy HH:mm')
                .format(detail.memberSince!.toLocal()),
          ),
        if (detail.isPsychic)
          PlatformSocialInfoRow(
            label: 'Canlı falcı',
            value: detail.psychicStatus ?? 'Onaylı',
          ),
        if (detail.isBanned)
          PlatformSocialInfoRow(
            label: 'Ban',
            value: detail.banReason ?? 'Askıda',
          ),
        if (!AdminUserPermissions.canViewFinance(access))
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Finans detayı için ödeme yöneticisi yetkisi gerekir.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

enum _FinanceFilter { all, jeton, cfc }

class _FinanceTab extends ConsumerStatefulWidget {
  const _FinanceTab({
    required this.detail,
    required this.history,
    required this.pendingPayments,
    required this.access,
    required this.onRefresh,
  });

  final AdminUserDetail detail;
  final List<Map<String, dynamic>> history;
  final List<Map<String, dynamic>> pendingPayments;
  final StaffAccess access;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends ConsumerState<_FinanceTab> {
  _FinanceFilter _filter = _FinanceFilter.all;

  List<Map<String, dynamic>> _filteredHistory() {
    if (_filter == _FinanceFilter.all) return widget.history;
    return widget.history.where((r) {
      final kind = (r['type'] ?? r['currency'] ?? '').toString().toLowerCase();
      if (_filter == _FinanceFilter.jeton) {
        return kind.contains('jeton') ||
            kind.contains('coin') ||
            r['coins'] != null;
      }
      return kind.contains('cfc');
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final access = widget.access;
    if (!AdminUserPermissions.canViewFinance(access)) {
      return const Center(child: Text('Finans görüntüleme yetkiniz yok.'));
    }

    final filtered = _filteredHistory();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (AdminUserPermissions.canEditFinance(access))
          AdminHubSectionCard(
            title: 'Hızlı işlemler',
            children: [
              PlatformSocialPrimaryButton(
                label: 'Jeton +/-',
                icon: Icons.monetization_on_outlined,
                onPressed: () async {
                  await AdminCreditSheet.show(
                    context,
                    ref: ref,
                    user: widget.detail.raw,
                    kind: AdminCreditKind.jeton,
                  );
                  widget.onRefresh();
                },
              ),
              const SizedBox(height: 8),
              PlatformSocialPrimaryButton(
                label: 'CFC +/-',
                icon: Icons.toll_outlined,
                onPressed: () async {
                  await AdminCreditSheet.show(
                    context,
                    ref: ref,
                    user: widget.detail.raw,
                    kind: AdminCreditKind.cfc,
                  );
                  widget.onRefresh();
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await AdminMembershipSheet.show(
                    context,
                    ref: ref,
                    user: widget.detail.raw,
                  );
                  widget.onRefresh();
                },
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: const Text('Gold / üyelik'),
              ),
            ],
          ),
        if (AdminUserPermissions.canReviewUserPayments(access) &&
            widget.pendingPayments.isNotEmpty)
          AdminHubSectionCard(
            title: 'Bekleyen ödeme talepleri',
            children: [
              ...widget.pendingPayments.map(
                (r) => PlatformSocialListRow(
                  title: resolvePaymentRequestType(r),
                  subtitle:
                      '${r['amount'] ?? r['coins'] ?? r['cfc'] ?? '—'} · ${r['id'] ?? ''}',
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: PlatformSocialPalette.gold,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: PlatformSocialPalette.success),
                        onPressed: () => AdminUserCommandActions.reviewPayment(
                          context,
                          ref,
                          request: r,
                          action: 'approve',
                          onDone: widget.onRefresh,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: PlatformSocialPalette.danger),
                        onPressed: () => AdminUserCommandActions.reviewPayment(
                          context,
                          ref,
                          request: r,
                          action: 'reject',
                          onDone: widget.onRefresh,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        const PlatformSocialSectionTitle('İşlem geçmişi'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Tümü'),
              selected: _filter == _FinanceFilter.all,
              onSelected: (_) => setState(() => _filter = _FinanceFilter.all),
            ),
            ChoiceChip(
              label: const Text('Jeton'),
              selected: _filter == _FinanceFilter.jeton,
              onSelected: (_) => setState(() => _filter = _FinanceFilter.jeton),
            ),
            ChoiceChip(
              label: const Text('CFC'),
              selected: _filter == _FinanceFilter.cfc,
              onSelected: (_) => setState(() => _filter = _FinanceFilter.cfc),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const Text(
            'Kayıt yok veya filtre sonucu boş.',
            style: TextStyle(
              fontSize: 12,
              color: PlatformSocialPalette.textMuted,
            ),
          )
        else
          ...filtered.map((r) => _FinanceRow(row: r)),
        if (AdminUserPermissions.canViewFinance(access))
          AdminUserFinanceLedgerSection(userId: widget.detail.userId),
      ],
    );
  }
}

class _GiftsTab extends StatelessWidget {
  const _GiftsTab({
    required this.detail,
    required this.collection,
    required this.album,
    required this.ledger,
    required this.access,
  });

  final AdminUserDetail detail;
  final GiftCollection? collection;
  final GiftAlbum? album;
  final List<AdminGiftLedgerRow> ledger;
  final StaffAccess access;

  @override
  Widget build(BuildContext context) {
    if (!AdminUserPermissions.canViewGifts(access)) {
      return const Center(child: Text('Hediye görüntüleme yetkiniz yok.'));
    }

    final items = [
      ...?album?.items,
      ...?collection?.received,
      ...?collection?.sent,
    ];
    return AdminHubTabScroll(
      children: [
        AdminHubSectionCard(
          title: 'Hediye koleksiyonu',
          children: [
            PlatformSocialInfoRow(
              label: 'Tamamlanma',
              value: '${collection?.percent ?? 0}%',
            ),
          ],
        ),
        if (ledger.isNotEmpty)
          AdminHubSectionCard(
            title: 'Hediye defteri',
            children: [
              ...ledger.take(40).map(
                (g) => PlatformSocialListRow(
                  title: g.giftName ?? g.giftId ?? 'Hediye',
                  subtitle: [
                    if (g.senderName != null) 'Gönderen: ${g.senderName}',
                    if (g.receiverName != null) 'Alan: ${g.receiverName}',
                    if (g.context != null) g.context!,
                  ].join(' · '),
                  leading: const Text('🎁', style: TextStyle(fontSize: 22)),
                  trailing: g.at != null
                      ? Text(
                          DateFormat('dd.MM HH:mm').format(g.at!),
                          style: const TextStyle(fontSize: 10),
                        )
                      : Text('x${g.amount}', style: const TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        if (items.isEmpty && ledger.isEmpty)
          adminHubEmpty('Hediye kaydı bulunamadı.')
        else if (items.isNotEmpty)
          AdminHubSectionCard(
            title: 'Koleksiyon öğeleri',
            children: [
              ...items.take(50).map(
                (g) => PlatformSocialListRow(
                  title: g.name.isNotEmpty ? g.name : g.giftId,
                  subtitle: 'x${g.count}',
                  leading: const Text('🎁', style: TextStyle(fontSize: 22)),
                ),
              ),
            ],
          ),
        if (ledger.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Zaman damgalı ledger için üretim `GET /api/admin/users/{id}/gifts` veya sesli oda denetimi kullanılır.',
              style: TextStyle(
                fontSize: 11,
                color: PlatformSocialPalette.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _BroadcastTab extends ConsumerWidget {
  const _BroadcastTab({
    required this.detail,
    required this.streamHistory,
    required this.roomHistory,
    required this.access,
    required this.onRefresh,
  });

  final AdminUserDetail detail;
  final List<AdminBroadcastHistoryRow> streamHistory;
  final List<AdminBroadcastHistoryRow> roomHistory;
  final StaffAccess access;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AdminUserPermissions.canViewBroadcasts(access)) {
      return const Center(child: Text('Yayın/oda görüntüleme yetkiniz yok.'));
    }

    return AdminHubTabScroll(
      children: [
        AdminHubSectionCard(
          title: 'Yayın & oda özeti',
          children: [
            PlatformSocialInfoRow(
              label: 'Açılan canlı yayın',
              value: '${detail.liveStreamCount}',
            ),
            PlatformSocialInfoRow(
              label: 'Açılan sesli oda',
              value: '${detail.voiceRoomCount}',
            ),
            PlatformSocialInfoRow(
              label: 'Canlı yayın açma',
              value: detail.canOpenLiveStream == null
                  ? '—'
                  : (detail.canOpenLiveStream! ? 'İzinli' : 'Kapalı'),
            ),
            PlatformSocialInfoRow(
              label: 'Sesli oda açma',
              value: detail.canOpenVoiceRoom == null
                  ? '—'
                  : (detail.canOpenVoiceRoom! ? 'İzinli' : 'Kapalı'),
            ),
          ],
        ),
        if (streamHistory.isNotEmpty)
          AdminHubSectionCard(
            title: 'Yayın geçmişi',
            children: streamHistory.take(20).map(_historyRow).toList(),
          ),
        if (roomHistory.isNotEmpty)
          AdminHubSectionCard(
            title: 'Oda geçmişi',
            children: roomHistory.take(20).map(_historyRow).toList(),
          ),
        AdminHubSectionCard(
          title: 'Yönetim',
          children: [
            AdminHubActionRow(
              title: 'Aktif yayınlar',
              icon: Icons.live_tv_outlined,
              onTap: () => context.push('/admin/live-streams'),
            ),
            AdminHubActionRow(
              title: 'Aktif sesli odalar',
              icon: Icons.meeting_room_outlined,
              onTap: () => context.push('/admin/voice-rooms'),
            ),
            if (AdminUserPermissions.canImpersonateRoomCreate(access))
              AdminHubActionRow(
                title: 'Kullanıcı adına oda aç',
                icon: Icons.add_circle_outline,
                onTap: () => AdminUserCommandActions.showCreateRoomSheet(
                  context,
                  ref,
                  userId: detail.userId,
                  onDone: onRefresh,
                ),
              ),
          ],
        ),
        if (streamHistory.isEmpty && roomHistory.isEmpty)
          const Text(
            'Liste için `GET /api/admin/users/{id}/streams|rooms` (yoksa boş).',
            style: TextStyle(
              fontSize: 11,
              color: PlatformSocialPalette.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _historyRow(AdminBroadcastHistoryRow row) {
    final when = row.startedAt != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(row.startedAt!)
        : '—';
    return PlatformSocialListRow(
      title: row.title ?? row.id ?? 'Kayıt',
      subtitle: [
        when,
        if (row.viewers != null) '${row.viewers} izleyici',
        if (row.durationSec != null) '${row.durationSec}s',
      ].join(' · '),
      leading: Icon(
        row.kind.contains('voice') ? Icons.meeting_room_outlined : Icons.live_tv,
        color: PlatformSocialPalette.accentSecondary,
      ),
    );
  }
}

class _PermissionsTab extends ConsumerWidget {
  const _PermissionsTab({
    required this.detail,
    required this.access,
    required this.liveTeller,
    required this.pkBanned,
    required this.animationSlots,
    required this.onSaved,
  });

  final AdminUserDetail detail;
  final StaffAccess access;
  final AdminLiveTellerSummary? liveTeller;
  final bool pkBanned;
  final Map<String, String?> animationSlots;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AdminUserPermissions.canEditProfile(access)) {
      return const Center(
        child: Text('Profil/rol düzenleme için kullanıcı yönetimi yetkisi gerekir.'),
      );
    }

    return AdminHubTabScroll(
      children: [
        AdminHubSectionCard(
          title: 'Profil & rol',
          children: [
            PlatformSocialPrimaryButton(
              label: 'Klasik düzenleme formu',
              icon: Icons.edit_outlined,
              onPressed: () async {
                await AdminUserManageSheet.show(
                  context,
                  ref: ref,
                  user: detail.raw,
                );
                onSaved();
              },
            ),
            const SizedBox(height: 10),
            PlatformSocialInfoRow(label: 'Mevcut rol', value: detail.role),
            PlatformSocialInfoRow(label: 'Üyelik', value: detail.membership),
          ],
        ),
        AdminHubSectionCard(
          title: 'İleri yetkiler',
          children: [
            if (AdminUserPermissions.canManagePsychic(access))
              AdminHubActionRow(
                title: 'Canlı falcı durumu',
                subtitle: liveTeller?.status ??
                    detail.psychicStatus ??
                    (detail.isPsychic ? 'Onaylı' : '—'),
                icon: Icons.auto_awesome,
                onTap: () => AdminUserCommandActions.showPsychicSheet(
                  context,
                  ref,
                  userId: detail.userId,
                  displayName: detail.displayName ?? detail.label,
                  teller: liveTeller,
                  onDone: onSaved,
                ),
              ),
            if (AdminUserPermissions.canSetWithdrawalLimit(access))
              AdminHubActionRow(
                title: 'Çekim limiti',
                subtitle: 'POST /api/admin/users/withdrawal-limit',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => AdminUserCommandActions.showWithdrawalLimitSheet(
                  context,
                  ref,
                  userId: detail.userId,
                  onDone: onSaved,
                ),
              ),
            if (AdminUserPermissions.canAssignSiteAnimation(access)) ...[
              AdminHubActionRow(
                title: 'Site animasyon / çerçeve',
                subtitle: animationSlots.isEmpty
                    ? 'Atama yok'
                    : animationSlots.entries
                        .where((e) => e.value != null)
                        .map((e) => e.key)
                        .join(', '),
                icon: Icons.animation_outlined,
                onTap: () => AdminUserCommandActions.showAnimationAssignSheet(
                  context,
                  ref,
                  userId: detail.userId,
                  onDone: onSaved,
                ),
              ),
              AdminHubActionRow(
                title: 'Tam animasyon atama sayfası',
                icon: Icons.open_in_new,
                onTap: () => AdminUserCommandActions.openFullAnimationPage(
                  context,
                  detail.userId,
                ),
              ),
            ],
            if (AdminUserPermissions.canManagePkBan(access))
              AdminHubActionRow(
                title: pkBanned ? 'PK ban kaldır' : 'PK ban',
                icon: Icons.sports_martial_arts_outlined,
                iconColor: pkBanned ? PlatformSocialPalette.danger : null,
                onTap: () => AdminUserCommandActions.togglePkBan(
                  context,
                  ref,
                  userId: detail.userId,
                  currentlyBanned: pkBanned,
                  onDone: onSaved,
                ),
              ),
          ],
        ),
        if (AdminUserPermissions.canManageFeatureFlags(access)) ...[
          AdminHubSectionCard(
            title: 'Özellik bayrakları',
            footer: const Text(
              'PATCH /api/admin/users/{id} ile güncellenir',
              style: TextStyle(
                fontSize: 11,
                color: PlatformSocialPalette.textMuted,
              ),
            ),
            children: [
              SwitchListTile(
                title: const Text('Canlı yayın açabilir'),
                value: detail.canOpenLiveStream ?? true,
                onChanged: (v) => _patchFlag(
                  ref,
                  context,
                  {'canOpenLiveStream': v, 'canBroadcast': v},
                ),
              ),
              SwitchListTile(
                title: const Text('Sesli oda açabilir'),
                value: detail.canOpenVoiceRoom ?? true,
                onChanged: (v) => _patchFlag(
                  ref,
                  context,
                  {'canOpenVoiceRoom': v, 'canCreateRoom': v},
                ),
              ),
              AdminDiscoveryPermissionsCard(
                hiddenFromDiscovery: detail.hiddenFromDiscovery,
                discoveryPriority: detail.discoveryPriority,
                canDecreasePriority: detail.discoveryPriority > 0,
                onHiddenChanged: (v) => _patchFlag(
                  ref,
                  context,
                  {'hiddenFromDiscovery': v},
                ),
                onPriorityDecrease: () => _patchFlag(
                  ref,
                  context,
                  {'discoveryPriority': detail.discoveryPriority - 1},
                ),
                onPriorityIncrease: () => _patchFlag(
                  ref,
                  context,
                  {'discoveryPriority': detail.discoveryPriority + 1},
                ),
              ),
            ],
          ),
        ],
        if (AdminUserPermissions.canBanUser(access))
          AdminHubSectionCard(
            title: 'Ban',
            children: [
              AdminHubActionRow(
                title: detail.isBanned ? 'Ban kaldır' : 'Kullanıcıyı banla',
                icon: Icons.block,
                iconColor: detail.isBanned ? PlatformSocialPalette.danger : null,
                onTap: () => _toggleBan(ref, context),
              ),
            ],
          ),
        const AdminRolePermissionsMatrix(),
      ],
    );
  }

  Future<void> _patchFlag(
    WidgetRef ref,
    BuildContext context,
    Map<String, dynamic> patch,
  ) async {
    try {
      await ref.read(adminRemoteProvider).updateUser(detail.userId, patch);
      onSaved();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncellendi')),
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

  Future<void> _toggleBan(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(adminRemoteProvider).updateUser(
        detail.userId,
        detail.isBanned
            ? {'isBanned': false, 'banned': false}
            : {'isBanned': true, 'banReason': 'admin_action'},
      );
      onSaved();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.activities, required this.access});

  final List<Map<String, dynamic>> activities;
  final StaffAccess access;

  @override
  Widget build(BuildContext context) {
    if (!AdminUserPermissions.canViewActivity(access)) {
      return const Center(child: Text('Aktivite görüntüleme yetkiniz yok.'));
    }
    if (activities.isEmpty) {
      return const Center(child: Text('Bu kullanıcı için aktivite bulunamadı.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final a = activities[i];
        final type =
            (a['activityType'] ?? a['type'] ?? 'aktivite').toString();
        final at = a['createdAt']?.toString();
        return ListTile(
          dense: true,
          title: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(a['description']?.toString() ?? ''),
          trailing: at != null
              ? Text(
                  DateFormat('dd.MM HH:mm').format(
                    DateTime.tryParse(at)?.toLocal() ?? DateTime.now(),
                  ),
                  style: const TextStyle(fontSize: 10),
                )
              : null,
        );
      },
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});
  final List<_Stat> items;

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 56) / 2;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in items)
          SizedBox(
            width: w,
            child: PlatformSocialStatTile(label: s.label, value: s.value),
          ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PlatformSocialInfoRow(label: label, value: value);
  }
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final kind = (row['type'] ?? row['currency'] ?? 'işlem').toString();
    final amount = row['amount'] ?? row['coins'];
    return PlatformSocialListRow(
      title: '$kind${amount != null ? ' · $amount' : ''}',
      subtitle: row['note']?.toString(),
      leading: const Icon(
        Icons.receipt_long_outlined,
        color: PlatformSocialPalette.accentSecondary,
      ),
    );
  }
}
