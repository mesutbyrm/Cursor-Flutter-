import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/agency_management_models.dart';
import '../providers/agency_management_providers.dart';
import '../widgets/agency_mgmt_widgets.dart';
import 'agency_performance_pages.dart' show AccrualTile;

mixin _Runner<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  var busy = false;

  Future<void> run(Future<String> Function() action, List<ProviderOrFamily> refresh) async {
    setState(() => busy = true);
    try {
      final msg = await action();
      if (mounted) showResult(context, msg);
      for (final p in refresh) {
        ref.invalidate(p);
      }
    } catch (e) {
      if (mounted) showResult(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

/// Ajansa gelen katılma başvuruları.
class AgencyJoinRequestsPage extends ConsumerStatefulWidget {
  const AgencyJoinRequestsPage({super.key});

  @override
  ConsumerState<AgencyJoinRequestsPage> createState() => _AgencyJoinRequestsPageState();
}

class _AgencyJoinRequestsPageState extends ConsumerState<AgencyJoinRequestsPage> with _Runner {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agencyJoinRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Katılma Başvuruları')),
      body: AsyncSection<List<JoinRequestView>>(
        value: async,
        onRetry: () => ref.invalidate(agencyJoinRequestsProvider),
        isEmpty: (l) => l.isEmpty,
        emptyText: 'Bekleyen başvuru yok.',
        builder: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(agencyJoinRequestsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final r in list)
                Card(
                  key: Key('join-request-${r.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.user != null) UserRefTile(user: r.user!, subtitle: fmtDate(r.createdAt, time: true)),
                        if (r.message != null) Text(r.message!),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          TextButton(
                            key: Key('join-reject-${r.id}'),
                            onPressed: busy
                                ? null
                                : () => run(() => ref.read(agencyManagementProvider).reviewJoinRequest(r.id, accept: false), [agencyJoinRequestsProvider]),
                            child: const Text('Reddet'),
                          ),
                          FilledButton(
                            key: Key('join-accept-${r.id}'),
                            onPressed: busy
                                ? null
                                : () => run(() => ref.read(agencyManagementProvider).reviewJoinRequest(r.id, accept: true), [agencyJoinRequestsProvider]),
                            child: const Text('Kabul et'),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ajans içi duyurular — yetkili yazar, tüm üyeler okur ve bildirim alır.
class AgencyAnnouncementsPage extends ConsumerStatefulWidget {
  const AgencyAnnouncementsPage({super.key});

  @override
  ConsumerState<AgencyAnnouncementsPage> createState() => _AgencyAnnouncementsPageState();
}

class _AgencyAnnouncementsPageState extends ConsumerState<AgencyAnnouncementsPage> with _Runner {
  Future<void> _compose() async {
    final result = await showDialog<(String, String, bool)>(context: context, builder: (_) => const _AnnouncementDialog());
    if (result == null || !mounted) return;
    await run(
      () => ref.read(agencyManagementProvider).postAnnouncement(title: result.$1, body: result.$2, pinned: result.$3),
      [agencyAnnouncementsProvider],
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agencyAnnouncementsProvider);
    final canPost = async.valueOrNull?.$2 ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajans Duyuruları')),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              key: const Key('announce-new'),
              onPressed: busy ? null : _compose,
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Duyuru'),
            )
          : null,
      body: AsyncSection<(List<AgencyAnnouncement>, bool)>(
        value: async,
        onRetry: () => ref.invalidate(agencyAnnouncementsProvider),
        isEmpty: (d) => d.$1.isEmpty,
        emptyText: 'Henüz duyuru yok.',
        builder: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            for (final a in d.$1)
              Card(
                child: ListTile(
                  leading: Icon(a.pinned ? Icons.push_pin_rounded : Icons.campaign_rounded),
                  title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${a.body}\n${fmtDate(a.createdAt, time: true)}'),
                  trailing: d.$2
                      ? IconButton(
                          tooltip: 'Kaldır',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: busy
                              ? null
                              : () => run(() => ref.read(agencyManagementProvider).deleteAnnouncement(a.id), [agencyAnnouncementsProvider]),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hedef hak edişleri — dönem kapatma, ödeme (ajans cüzdanından), iptal.
class AgencyAccrualsPage extends ConsumerStatefulWidget {
  const AgencyAccrualsPage({super.key});

  @override
  ConsumerState<AgencyAccrualsPage> createState() => _AgencyAccrualsPageState();
}

class _AgencyAccrualsPageState extends ConsumerState<AgencyAccrualsPage> with _Runner {
  Future<void> _close(String period) async {
    if (!await confirmDialog(
      context,
      title: '${periodLabelTr(period)} dönemi kapat',
      body: 'Biten son ${periodLabelTr(period).toLowerCase()} dönem, doğrulanmış yayın süresine göre değerlendirilir. '
          'Aynı dönem ikinci kez kapatılamaz.',
      ok: 'Kapat',
    )) {
      return;
    }
    if (!mounted) return;
    await run(() => ref.read(agencyManagementProvider).closePeriod(period), [agencyAccrualsProvider]);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agencyAccrualsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hak Edişler')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(agencyAccrualsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Önceki dönemi kapat:'),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final p in const ['daily', 'weekly', 'monthly'])
                OutlinedButton(key: Key('close-$p'), onPressed: busy ? null : () => _close(p), child: Text(periodLabelTr(p))),
            ]),
            const SizedBox(height: 12),
            AsyncSection<List<AccrualView>>(
              value: async,
              onRetry: () => ref.invalidate(agencyAccrualsProvider),
              isEmpty: (l) => l.isEmpty,
              emptyText: 'Henüz hak ediş yok.',
              builder: (list) => Column(children: [
                for (final a in list)
                  AccrualTile(
                    accrual: a,
                    busy: busy,
                    showUser: true,
                    onPay: () async {
                      if (!await confirmDialog(context, title: 'Bonusu öde', body: '${a.bonusJeton} Jeton ajans cüzdanından aktarılacak.', ok: 'Öde')) return;
                      if (!mounted) return;
                      await run(() => ref.read(agencyManagementProvider).payAccrual(a.id), [agencyAccrualsProvider]);
                    },
                    onVoid: () async {
                      final reason = await textInputDialog(context, title: 'Hak edişi iptal et', hint: 'Gerekçe (zorunlu)');
                      if (reason == null || reason.length < 3 || !mounted) return;
                      await run(() => ref.read(agencyManagementProvider).voidAccrual(a.id, reason), [agencyAccrualsProvider]);
                    },
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Çalışan yetkileri (yalnız sahip).
class AgencyStaffPage extends ConsumerStatefulWidget {
  const AgencyStaffPage({super.key});

  @override
  ConsumerState<AgencyStaffPage> createState() => _AgencyStaffPageState();
}

class _AgencyStaffPageState extends ConsumerState<AgencyStaffPage> with _Runner {
  Future<void> _edit({required String userId, required String name, List<String> current = const []}) async {
    final selected = Set<String>.from(current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('$name · yetkiler'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final e in agencyStaffPermissionLabels.entries)
              CheckboxListTile(
                key: Key('perm-${e.key}'),
                contentPadding: EdgeInsets.zero,
                value: selected.contains(e.key),
                title: Text(e.value),
                onChanged: (v) => setLocal(() => v == true ? selected.add(e.key) : selected.remove(e.key)),
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(key: const Key('perm-save'), onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    await run(() => ref.read(agencyManagementProvider).setStaff(userId, selected.toList()), [agencyStaffProvider]);
  }

  Future<void> _pickMember() async {
    List<MemberPerfRow> members;
    try {
      // Kullanıcı kimlikleri performans listesinden (üyelik satır kimliği değil).
      members = (await ref.read(agencyPerformanceProvider('weekly').future)).members;
    } catch (e) {
      if (mounted) showResult(context, errorText(e), error: true);
      return;
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<MemberPerfRow>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          const ListTile(title: Text('Üye seçin')),
          for (final m in members.where((m) => m.role != 'owner' && m.status == 'active'))
            ListTile(title: Text(m.user.display), subtitle: Text(m.role ?? 'member'), onTap: () => Navigator.pop(ctx, m)),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    await _edit(userId: picked.user.id, name: picked.user.display);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agencyStaffProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Çalışan Yetkileri')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : _pickMember,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Yetki ver'),
      ),
      body: AsyncSection<List<StaffEntry>>(
        value: async,
        onRetry: () => ref.invalidate(agencyStaffProvider),
        isEmpty: (l) => l.isEmpty,
        emptyText: 'Yetkili çalışan yok. Yöneticiler varsayılan olarak üye, davet, rapor ve duyuru yetkisine sahiptir.',
        builder: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            for (final s in list)
              Card(
                child: ListTile(
                  title: Text(s.user?.display ?? s.userId),
                  subtitle: Text(s.permissions.isEmpty
                      ? 'Yetki yok'
                      : s.permissions.map((p) => agencyStaffPermissionLabels[p] ?? p).join(', ')),
                  onTap: busy ? null : () => _edit(userId: s.userId, name: s.user?.display ?? 'Üye', current: s.permissions),
                  trailing: IconButton(
                    tooltip: 'Yetkileri kaldır',
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: busy ? null : () => run(() => ref.read(agencyManagementProvider).removeStaff(s.userId), [agencyStaffProvider]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog();

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  var _pinned = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni duyuru'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(key: const Key('announce-title'), controller: _title, decoration: const InputDecoration(labelText: 'Başlık')),
          TextField(key: const Key('announce-body'), controller: _body, maxLines: 5, decoration: const InputDecoration(labelText: 'Metin')),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _pinned,
            onChanged: (v) => setState(() => _pinned = v ?? false),
            title: const Text('Başa sabitle'),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(
          key: const Key('announce-send'),
          onPressed: () => Navigator.pop(context, (_title.text.trim(), _body.text.trim(), _pinned)),
          child: const Text('Yayımla'),
        ),
      ],
    );
  }
}
