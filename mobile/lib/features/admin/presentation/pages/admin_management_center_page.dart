import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../admin_web/presentation/providers/admin_web_access_provider.dart';
import '../navigation/admin_nav.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/admin_pending_counts_provider.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_credit_sheet.dart';
import '../widgets/admin_membership_sheet.dart';
import '../widgets/admin_pending_ops_bar.dart';
import '../widgets/admin_stats_list_sheet.dart';
import '../widgets/admin_user_picker.dart';
import 'admin_panel_page.dart' show AdminCreditKind, AdminStatsKind;

/// Görünür menü grupları: yetkiye göre süzülmüş, boş gruplar atılmış.
List<({AdminNavGroup group, List<(AdminNavItem, AdminNavTarget)> items})>
    visibleAdminNav(StaffAccess access, {required bool webAccess, String query = ''}) {
  final q = query.trim().toLowerCase();
  final out =
      <({AdminNavGroup group, List<(AdminNavItem, AdminNavTarget)> items})>[];
  for (final g in adminNavGroups(access)) {
    final items = <(AdminNavItem, AdminNavTarget)>[];
    for (final item in g.items) {
      final target = item.resolve(webAccess: webAccess);
      if (target == null) continue;
      if (q.isNotEmpty &&
          !item.label.toLowerCase().contains(q) &&
          !item.description.toLowerCase().contains(q) &&
          !g.title.toLowerCase().contains(q)) {
        continue;
      }
      items.add((item, target));
    }
    if (items.isNotEmpty) out.add((group: g, items: items));
  }
  return out;
}

/// Yönetim Paneli — uygulamadaki TEK yönetim menüsü.
///
/// Web yönetim paneliyle (canlifal.com/admin) aynı gruplar ve aynı başlıklar;
/// her işlev yalnızca bir kez bulunur. Uygulamada çalışan ekranı olan madde
/// yerel ekranda, diğerleri web panelindeki aynı sayfada (uygulama içinde)
/// açılır.
class AdminManagementCenterPage extends ConsumerStatefulWidget {
  const AdminManagementCenterPage({super.key});

  @override
  ConsumerState<AdminManagementCenterPage> createState() =>
      _AdminManagementCenterPageState();
}

class _AdminManagementCenterPageState
    extends ConsumerState<AdminManagementCenterPage> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(adminPendingCountsProvider);
    ref.invalidate(adminPanelBadgeCountsProvider);
  }

  Future<void> _open(AdminNavItem item, AdminNavTarget t) async {
    if (t.route != null) {
      await context.push(t.route!);
    } else if (t.webPath != null) {
      await context.push(adminWebRoute(t.webPath!, item.label));
    } else if (t.action != null) {
      await _runAction(t.action!);
    }
    if (mounted) _refresh();
  }

  Future<void> _runAction(AdminNavAction action) async {
    switch (action) {
      case AdminNavAction.creditJeton:
      case AdminNavAction.creditCfc:
        final user = await AdminUserPicker.show(context, ref);
        if (user == null || !mounted) return;
        await AdminCreditSheet.show(
          context,
          ref: ref,
          user: user,
          kind: action == AdminNavAction.creditJeton
              ? AdminCreditKind.jeton
              : AdminCreditKind.cfc,
        );
      case AdminNavAction.grantMembership:
        final user = await AdminUserPicker.show(context, ref);
        if (user == null || !mounted) return;
        await AdminMembershipSheet.show(context, ref: ref, user: user);
      case AdminNavAction.todayStats:
        await _showTodayStats();
    }
  }

  Future<void> _showTodayStats() async {
    const kinds = <(AdminStatsKind, String, IconData)>[
      (AdminStatsKind.todayMembers, 'Bugün üye olanlar', Icons.person_add_alt_1_rounded),
      (AdminStatsKind.todayJetonBuyers, 'Bugün jeton alanlar', Icons.monetization_on_outlined),
      (AdminStatsKind.roomOpeners, 'Oda açanlar', Icons.meeting_room_outlined),
      (AdminStatsKind.broadcasters, 'Yayın yapanlar', Icons.live_tv_rounded),
      (AdminStatsKind.topEarners, 'En çok kazananlar', Icons.emoji_events_outlined),
      (AdminStatsKind.topGiftSenders, 'En çok hediye atanlar', Icons.card_giftcard_rounded),
    ];
    final kind = await showModalBottomSheet<AdminStatsKind>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final k in kinds)
              ListTile(
                leading: Icon(k.$3),
                title: Text(k.$2),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(ctx, k.$1),
              ),
          ],
        ),
      ),
    );
    if (kind == null || !mounted) return;
    await AdminStatsListSheet.show(context, ref: ref, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    final webAccess = ref.watch(adminWebAccessProvider);
    final c = context.colors;

    Widget body;
    if (!access.canAccessAdminHome) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: c.onSurfaceMuted),
              const SizedBox(height: 12),
              Text(
                'Bu alan için yetkiniz yok.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.onSurfaceVariant, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    } else {
      final groups = visibleAdminNav(access, webAccess: webAccess, query: _query);
      body = RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            Text(
              'Platform yönetimi ve kontrol merkezi',
              style: TextStyle(color: c.onSurfaceMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Ayar veya bölüm ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor: mockCardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: mockCardBorder(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: mockCardBorder(context)),
                ),
              ),
            ),
            if (_query.isEmpty && access.canManagePayments) ...[
              const SizedBox(height: 14),
              _SectionHeader(emoji: '⏳', title: 'Bekleyen İşlemler'),
              const SizedBox(height: 8),
              const AdminPendingOpsBar(),
            ],
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'Sonuç bulunamadı',
                    style: TextStyle(color: c.onSurfaceMuted),
                  ),
                ),
              ),
            for (final g in groups) ...[
              const SizedBox(height: 18),
              _SectionHeader(emoji: g.group.emoji, title: g.group.title),
              const SizedBox(height: 8),
              _GroupCard(
                children: [
                  for (var i = 0; i < g.items.length; i++)
                    _NavTile(
                      item: g.items[i].$1,
                      target: g.items[i].$2,
                      showDivider: i < g.items.length - 1,
                      onTap: () => _open(g.items[i].$1, g.items[i].$2),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return MockScaffold(
      title: 'Yönetim Paneli',
      startAligned: true,
      actions: [
        if (access.canAccessAdminHome)
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
      ],
      body: body,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.emoji, required this.title});

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: mockCardColor(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: mockCardBorder(context)),
      ),
      child: Column(children: children),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.target,
    required this.showDivider,
    required this.onTap,
  });

  final AdminNavItem item;
  final AdminNavTarget target;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(item.icon, color: c.primary),
          title: Text(
            item.label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: c.onSurfaceMuted),
          ),
          trailing: Icon(
            target.isWeb ? Icons.language_rounded : Icons.chevron_right_rounded,
            size: 20,
            color: c.onSurfaceMuted,
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 56, color: mockCardBorder(context)),
      ],
    );
  }
}
