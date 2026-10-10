import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/agency_management_models.dart';
import '../providers/agency_management_providers.dart';
import '../widgets/agency_mgmt_widgets.dart';

/// Ajans üyeleri: aktif, bekleyen, ayrılmış, engellenmiş. Engelleme üyeyi çıkarır
/// ve tekrar başvuru/davetle katılımı kapatır; geçmiş kayıtlar silinmez.
class AgencyMembersPage extends ConsumerStatefulWidget {
  const AgencyMembersPage({super.key});

  @override
  ConsumerState<AgencyMembersPage> createState() => _AgencyMembersPageState();
}

class _AgencyMembersPageState extends ConsumerState<AgencyMembersPage> {
  var _busy = false;

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final msg = await action();
      if (mounted) showResult(context, msg);
      ref.invalidate(agencyRosterProvider);
      ref.invalidate(agencyJoinRequestsProvider);
    } catch (e) {
      if (mounted) showResult(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _block(RosterEntry e) async {
    final reason = await textInputDialog(
      context,
      title: '${e.user.display} engellensin mi?',
      hint: 'Gerekçe (isteğe bağlı). Üyeyse ajanstan çıkarılır; geçmiş kayıtlar silinmez.',
      fieldKey: const Key('block-reason'),
    );
    if (reason == null || !mounted) return;
    await _run(() => ref.read(agencyManagementProvider).blockUser(e.user.id, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agencyRosterProvider);
    final r = async.valueOrNull;
    String tab(String label, List<RosterEntry>? l) => l == null ? label : '$label (${l.length})';
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Üyeler'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: tab('Aktif', r == null ? null : [...r.active, ...r.inactive])),
              Tab(text: tab('Bekleyen', r?.pending)),
              Tab(text: tab('Ayrılmış', r?.left)),
              Tab(key: const Key('tab-blocked'), text: tab('Engellenmiş', r?.blocked)),
            ],
          ),
        ),
        body: AsyncSection<AgencyRoster>(
          value: async,
          onRetry: () => ref.invalidate(agencyRosterProvider),
          builder: (d) => TabBarView(
            children: [
              _list(
                [...d.active, ...d.inactive],
                empty: 'Aktif üye yok.',
                subtitle: (e) => '${e.role == 'owner' ? 'Sahip' : e.role == 'manager' ? 'Yönetici' : 'Yayıncı'} · katılım ${fmtDate(e.since)}'
                    '${d.inactive.contains(e) ? ' · pasif' : ''}',
                trailing: (e) => e.role == 'owner'
                    ? null
                    : PopupMenuButton<String>(
                        key: Key('member-menu-${e.user.id}'),
                        enabled: !_busy,
                        onSelected: (v) {
                          if (v == 'perf') context.push('/ajans/performans/${e.user.id}');
                          if (v == 'block') _block(e);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'perf', child: Text('Performans')),
                          PopupMenuItem(value: 'block', child: Text('Engelle ve çıkar')),
                        ],
                      ),
              ),
              _list(
                d.pending,
                empty: 'Bekleyen başvuru veya davet yok.',
                subtitle: (e) => '${e.kind == 'invite' ? 'Gönderilen davet' : 'Katılma başvurusu'} · ${fmtDate(e.since)}'
                    '${e.note != null ? '\n${e.note}' : ''}',
                trailing: (e) => e.kind == 'request'
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          tooltip: 'Reddet',
                          onPressed: _busy ? null : () => _run(() => ref.read(agencyManagementProvider).reviewJoinRequest(e.id!, accept: false)),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        IconButton(
                          key: Key('roster-accept-${e.id}'),
                          tooltip: 'Kabul et',
                          onPressed: _busy ? null : () => _run(() => ref.read(agencyManagementProvider).reviewJoinRequest(e.id!, accept: true)),
                          icon: const Icon(Icons.check_rounded, color: Color(0xFF22C55E)),
                        ),
                      ])
                    : null,
              ),
              _list(
                d.left,
                empty: 'Ayrılmış üye yok.',
                subtitle: (e) => '${fmtDate(e.since)} – ${fmtDate(e.until)}'
                    '${MembershipHistoryEntry(agencyId: '', agencyName: '', endedBy: e.endedBy).endedByLabel.isNotEmpty ? ' · ${MembershipHistoryEntry(agencyId: '', agencyName: '', endedBy: e.endedBy).endedByLabel}' : ''}'
                    '${e.note != null ? '\n${e.note}' : ''}',
              ),
              _list(
                d.blocked,
                empty: 'Engellenmiş kullanıcı yok.',
                subtitle: (e) => 'Engellendi ${fmtDate(e.since)}${e.note != null ? ' · ${e.note}' : ''}',
                trailing: (e) => TextButton(
                  key: Key('unblock-${e.user.id}'),
                  onPressed: _busy ? null : () => _run(() => ref.read(agencyManagementProvider).unblockUser(e.user.id)),
                  child: const Text('Engeli kaldır'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(
    List<RosterEntry> items, {
    required String empty,
    required String Function(RosterEntry) subtitle,
    Widget? Function(RosterEntry)? trailing,
  }) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(agencyRosterProvider.future),
      child: items.isEmpty
          ? ListView(children: [InfoState(icon: Icons.inbox_outlined, text: empty)])
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in items) UserRefTile(user: e.user, subtitle: subtitle(e), trailing: trailing?.call(e)),
              ],
            ),
    );
  }
}
