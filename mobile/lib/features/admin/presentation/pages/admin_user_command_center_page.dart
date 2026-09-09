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
    _tabs = TabController(length: 6, vsync: this);
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
              indicatorColor: AppThemeColors.accentPink,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Özet'),
                Tab(text: 'Finans'),
                Tab(text: 'Hediyeler'),
                Tab(text: 'Yayın/Oda'),
                Tab(text: 'Yetkiler'),
                Tab(text: 'Aktivite'),
              ],
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppThemeColors.coinGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        warnings.join(' · '),
        style: const TextStyle(fontSize: 11),
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
        _PermissionsTab(
          detail: d,
          access: access,
          liveTeller: bundle.liveTeller,
          pkBanned: bundle.pkBanned,
          animationSlots: bundle.siteAnimationSlots,
          onSaved: onRefresh,
        ),
        _ActivityTab(activities: bundle.activities, access: access),
      ],
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
                    Text('@${detail.username}',
                        style: TextStyle(color: Colors.grey.shade500)),
                  Text(
                    'Rol: ${detail.role} · ${detail.membership}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (detail.isOnline)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Online', style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 20),
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
        _InfoTile(
          label: 'Üyelik süresi',
          value: formatMembershipTenure(detail.memberSince),
        ),
        _InfoTile(
          label: 'Son online',
          value: formatLastOnline(
            detail.lastSeenAt,
            isOnline: detail.isOnline,
          ),
        ),
        if (detail.memberSince != null)
          _InfoTile(
            label: 'Kayıt tarihi',
            value: DateFormat('dd.MM.yyyy HH:mm')
                .format(detail.memberSince!.toLocal()),
          ),
        if (detail.isPsychic)
          _InfoTile(
            label: 'Canlı falcı',
            value: detail.psychicStatus ?? 'Onaylı',
          ),
        if (detail.isBanned)
          _InfoTile(
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await AdminCreditSheet.show(
                    context,
                    ref: ref,
                    user: widget.detail.raw,
                    kind: AdminCreditKind.jeton,
                  );
                  widget.onRefresh();
                },
                icon: const Icon(Icons.monetization_on_outlined, size: 18),
                label: const Text('Jeton +/-'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await AdminCreditSheet.show(
                    context,
                    ref: ref,
                    user: widget.detail.raw,
                    kind: AdminCreditKind.cfc,
                  );
                  widget.onRefresh();
                },
                icon: const Icon(Icons.toll_outlined, size: 18),
                label: const Text('CFC +/-'),
              ),
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
        const SizedBox(height: 16),
        if (AdminUserPermissions.canReviewUserPayments(access) &&
            widget.pendingPayments.isNotEmpty) ...[
          const Text(
            'Bekleyen ödeme talepleri',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...widget.pendingPayments.map(
            (r) => Card(
              child: ListTile(
                title: Text(resolvePaymentRequestType(r)),
                subtitle: Text(
                  '${r['amount'] ?? r['coins'] ?? r['cfc'] ?? '—'} · ${r['id'] ?? ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => AdminUserCommandActions.reviewPayment(
                        context,
                        ref,
                        request: r,
                        action: 'approve',
                        onDone: widget.onRefresh,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppThemeColors.liveRed),
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
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'İşlem geçmişi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
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
            style: TextStyle(fontSize: 12),
          )
        else
          ...filtered.map((r) => _FinanceRow(row: r)),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Koleksiyon tamamlanma: ${collection?.percent ?? 0}%',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (ledger.isNotEmpty) ...[
          const Text(
            'Hediye defteri',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...ledger.take(40).map(
                (g) => ListTile(
                  dense: true,
                  leading: const Text('🎁'),
                  title: Text(g.giftName ?? g.giftId ?? 'Hediye'),
                  subtitle: Text(
                    [
                      if (g.senderName != null) 'Gönderen: ${g.senderName}',
                      if (g.receiverName != null) 'Alan: ${g.receiverName}',
                      if (g.context != null) g.context!,
                    ].join(' · '),
                  ),
                  trailing: g.at != null
                      ? Text(
                          DateFormat('dd.MM HH:mm').format(g.at!),
                          style: const TextStyle(fontSize: 10),
                        )
                      : Text('x${g.amount}', style: const TextStyle(fontSize: 11)),
                ),
              ),
          const SizedBox(height: 16),
        ],
        if (items.isEmpty && ledger.isEmpty)
          const Text('Hediye kaydı bulunamadı.')
        else if (items.isNotEmpty)
          ...items.take(50).map(
                (g) => ListTile(
                  leading: Text(
                    g.iconUrl != null && g.iconUrl!.isNotEmpty ? '🎁' : '🎁',
                  ),
                  title: Text(g.name.isNotEmpty ? g.name : g.giftId),
                  subtitle: Text('x${g.count}'),
                ),
              ),
        if (ledger.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Zaman damgalı ledger için üretim `GET /api/admin/users/{id}/gifts` veya sesli oda denetimi kullanılır.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _InfoTile(
          label: 'Açılan canlı yayın',
          value: '${detail.liveStreamCount}',
        ),
        _InfoTile(label: 'Açılan sesli oda', value: '${detail.voiceRoomCount}'),
        _InfoTile(
          label: 'Canlı yayın açma',
          value: detail.canOpenLiveStream == null
              ? '—'
              : (detail.canOpenLiveStream! ? 'İzinli' : 'Kapalı'),
        ),
        _InfoTile(
          label: 'Sesli oda açma',
          value: detail.canOpenVoiceRoom == null
              ? '—'
              : (detail.canOpenVoiceRoom! ? 'İzinli' : 'Kapalı'),
        ),
        const SizedBox(height: 16),
        if (streamHistory.isNotEmpty) ...[
          const Text(
            'Yayın geçmişi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          ...streamHistory.take(20).map(_historyTile),
          const SizedBox(height: 12),
        ],
        if (roomHistory.isNotEmpty) ...[
          const Text(
            'Oda geçmişi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          ...roomHistory.take(20).map(_historyTile),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => context.push('/admin/live-streams'),
          icon: const Icon(Icons.live_tv_outlined),
          label: const Text('Aktif yayınlar'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.push('/admin/voice-rooms'),
          icon: const Icon(Icons.meeting_room_outlined),
          label: const Text('Aktif sesli odalar'),
        ),
        if (AdminUserPermissions.canImpersonateRoomCreate(access))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FilledButton.icon(
              onPressed: () => AdminUserCommandActions.showCreateRoomSheet(
                context,
                ref,
                userId: detail.userId,
                onDone: onRefresh,
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Kullanıcı adına oda aç'),
            ),
          ),
        if (streamHistory.isEmpty && roomHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Liste için `GET /api/admin/users/{id}/streams|rooms` (yoksa boş).',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _historyTile(AdminBroadcastHistoryRow row) {
    final when = row.startedAt != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(row.startedAt!)
        : '—';
    return ListTile(
      dense: true,
      leading: Icon(
        row.kind.contains('voice') ? Icons.meeting_room_outlined : Icons.live_tv,
        size: 20,
      ),
      title: Text(row.title ?? row.id ?? 'Kayıt'),
      subtitle: Text(
        [
          when,
          if (row.viewers != null) '${row.viewers} izleyici',
          if (row.durationSec != null) '${row.durationSec}s',
        ].join(' · '),
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FilledButton.icon(
          onPressed: () async {
            await AdminUserManageSheet.show(
              context,
              ref: ref,
              user: detail.raw,
            );
            onSaved();
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Klasik düzenleme formu'),
        ),
        const SizedBox(height: 16),
        _InfoTile(label: 'Mevcut rol', value: detail.role),
        _InfoTile(label: 'Üyelik', value: detail.membership),
        if (AdminUserPermissions.canManagePsychic(access))
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Canlı falcı durumu'),
            subtitle: Text(
              liveTeller?.status ??
                  detail.psychicStatus ??
                  (detail.isPsychic ? 'Onaylı' : '—'),
            ),
            trailing: const Icon(Icons.chevron_right),
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
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Çekim limiti'),
            subtitle: const Text('POST /api/admin/users/withdrawal-limit'),
            onTap: () => AdminUserCommandActions.showWithdrawalLimitSheet(
              context,
              ref,
              userId: detail.userId,
              onDone: onSaved,
            ),
          ),
        if (AdminUserPermissions.canAssignSiteAnimation(access)) ...[
          ListTile(
            leading: const Icon(Icons.animation_outlined),
            title: const Text('Site animasyon / çerçeve'),
            subtitle: Text(
              animationSlots.isEmpty
                  ? 'Atama yok'
                  : animationSlots.entries
                      .where((e) => e.value != null)
                      .map((e) => e.key)
                      .join(', '),
            ),
            onTap: () => AdminUserCommandActions.showAnimationAssignSheet(
              context,
              ref,
              userId: detail.userId,
              onDone: onSaved,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Tam animasyon atama sayfası'),
            onTap: () => AdminUserCommandActions.openFullAnimationPage(
              context,
              detail.userId,
            ),
          ),
        ],
        if (AdminUserPermissions.canManagePkBan(access))
          ListTile(
            leading: Icon(
              Icons.sports_martial_arts_outlined,
              color: pkBanned ? AppThemeColors.liveRed : null,
            ),
            title: Text(pkBanned ? 'PK ban kaldır' : 'PK ban'),
            onTap: () => AdminUserCommandActions.togglePkBan(
              context,
              ref,
              userId: detail.userId,
              currentlyBanned: pkBanned,
              onDone: onSaved,
            ),
          ),
        if (AdminUserPermissions.canManageFeatureFlags(access)) ...[
          const Divider(),
          const Text(
            'Özellik bayrakları — PATCH /api/admin/users/{id} ile güncellenir',
            style: TextStyle(fontSize: 12),
          ),
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
        ],
        if (AdminUserPermissions.canBanUser(access))
          ListTile(
            leading: Icon(
              Icons.block,
              color: detail.isBanned ? AppThemeColors.liveRed : null,
            ),
            title: Text(detail.isBanned ? 'Ban kaldır' : 'Kullanıcıyı banla'),
            onTap: () => _toggleBan(ref, context),
          ),
        const Divider(height: 24),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in items)
          Container(
            width: (MediaQuery.sizeOf(context).width - 56) / 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
                Text(s.label, style: const TextStyle(fontSize: 10)),
              ],
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade500)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final kind = (row['type'] ?? row['currency'] ?? 'işlem').toString();
    final amount = row['amount'] ?? row['coins'];
    return ListTile(
      dense: true,
      title: Text('$kind${amount != null ? ' · $amount' : ''}'),
      subtitle: row['note'] != null ? Text(row['note'].toString()) : null,
    );
  }
}
