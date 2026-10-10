import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/agency_management_models.dart';
import '../providers/agency_management_providers.dart';
import '../widgets/agency_mgmt_widgets.dart';
import 'agencies_page.dart' show PromiseCard;

/// Mobil yönetici: vaat onayı, şüpheli işlem uyarıları, ajans performansı.
/// Yetkiyi sunucu (RBAC `agency.manage` / `agency.report.view`) denetler.
class AdminAgencyManagementPage extends ConsumerStatefulWidget {
  const AdminAgencyManagementPage({super.key});

  @override
  ConsumerState<AdminAgencyManagementPage> createState() => _AdminAgencyManagementPageState();
}

class _AdminAgencyManagementPageState extends ConsumerState<AdminAgencyManagementPage> {
  var _status = 'pending';
  var _days = 7;
  var _period = 'weekly';
  String? _agencyId;
  var _busy = false;

  Future<void> _review(AdminPromiseVersion v, bool approve) async {
    String? note;
    if (approve) {
      if (!await confirmDialog(
        context,
        title: 'Onayla ve yayımla',
        body: 'Sürüm ${v.version.version} yayımlanır ve değiştirilemez.',
        ok: 'Onayla',
        okKey: const Key('admin-promise-approve-confirm'),
      )) {
        return;
      }
    } else {
      note = await textInputDialog(context, title: 'Ret gerekçesi', hint: 'En az 5 karakter', fieldKey: const Key('admin-reject-note'));
      if (note == null) return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final msg = await ref.read(agencyManagementProvider).adminReviewPromise(v.version.id, approve: approve, note: note);
      if (mounted) showResult(context, msg);
      ref.invalidate(adminAgencyPromisesProvider(_status));
    } catch (e) {
      if (mounted) showResult(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajans Yönetimi'),
          bottom: const TabBar(tabs: [Tab(text: 'Vaat Onayı'), Tab(text: 'Şüpheli'), Tab(text: 'Performans')]),
        ),
        body: TabBarView(children: [_promises(), _alerts(), _performance()]),
      ),
    );
  }

  Widget _promises() {
    final async = ref.watch(adminAgencyPromisesProvider(_status));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(spacing: 8, children: [
          for (final s in const [('pending', 'Bekleyen'), ('approved', 'Yayında'), ('rejected', 'Reddedilen'), ('all', 'Tümü')])
            ChoiceChip(label: Text(s.$2), selected: _status == s.$1, onSelected: (_) => setState(() => _status = s.$1)),
        ]),
        const SizedBox(height: 8),
        AsyncSection<List<AdminPromiseVersion>>(
          value: async,
          onRetry: () => ref.invalidate(adminAgencyPromisesProvider(_status)),
          isEmpty: (l) => l.isEmpty,
          emptyText: 'Kayıt yok.',
          builder: (list) => Column(children: [
            for (final v in list)
              PromiseCard(
                promise: v.version,
                footer: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('${v.agencyName} · ${v.version.statusLabel}', style: Theme.of(context).textTheme.bodySmall),
                  if (v.currentApproved != null)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text('Yayındaki sürüm ${v.currentApproved!.version}', style: const TextStyle(fontSize: 13)),
                      children: [Text(v.currentApproved!.body)],
                    ),
                  if (v.version.status == 'pending')
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(onPressed: _busy ? null : () => _review(v, false), child: const Text('Reddet')),
                      FilledButton(
                        key: Key('admin-approve-${v.version.id}'),
                        onPressed: _busy ? null : () => _review(v, true),
                        child: const Text('Onayla'),
                      ),
                    ]),
                ]),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _alerts() {
    final async = ref.watch(adminAgencyAlertsProvider(_days));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(spacing: 8, children: [
          for (final d in const [1, 7, 30, 90])
            ChoiceChip(label: Text('$d gün'), selected: _days == d, onSelected: (_) => setState(() => _days = d)),
        ]),
        const SizedBox(height: 8),
        AsyncSection<List<AgencyAlertView>>(
          value: async,
          onRetry: () => ref.invalidate(adminAgencyAlertsProvider(_days)),
          isEmpty: (l) => l.isEmpty,
          emptyText: 'Bu dönemde uyarı yok.',
          builder: (list) => Column(children: [
            for (final a in list)
              Card(
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: a.severity == 'high' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                  title: Text('${a.kindLabel} · ${a.agencyName}'),
                  subtitle: Text('${a.message}\n${fmtDate(a.at, time: true)} · ${a.refCount} kayıt'),
                ),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _performance() {
    final agencies = ref.watch(agenciesListProvider(('hours', '')));
    final id = _agencyId;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        agencies.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(errorText(e)),
          data: (list) => DropdownButtonFormField<String>(
            initialValue: id,
            hint: const Text('Ajans seçin'),
            isExpanded: true,
            items: [for (final a in list) DropdownMenuItem(value: a.id, child: Text(a.name, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => _agencyId = v),
          ),
        ),
        const SizedBox(height: 8),
        PeriodChips(value: _period, onChanged: (p) => setState(() => _period = p)),
        const SizedBox(height: 8),
        if (id == null)
          const Text('Doğrulanmış video yayın süresini görmek için ajans seçin.')
        else
          AsyncSection<List<Map<String, dynamic>>>(
            value: ref.watch(adminAgencyPerformanceProvider((id, _period))),
            onRetry: () => ref.invalidate(adminAgencyPerformanceProvider((id, _period))),
            isEmpty: (l) => l.isEmpty,
            emptyText: 'Üye yok.',
            builder: (rows) {
              final sorted = [...rows]..sort((a, b) => ((b['dogrulanmis_dakika'] ?? 0) as num).compareTo((a['dogrulanmis_dakika'] ?? 0) as num));
              return Column(children: [
                for (final r in sorted)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('@${r['kullanici']}'),
                    subtitle: Text('${formatMinutes(((r['dogrulanmis_dakika'] ?? 0) as num).toInt())} · ${r['aktif_gun']} gün · '
                        '${r['oturum']} yayın (${r['kesintili_oturum']} kesinti) · ${r['hediye_jeton']} Jeton hediye'),
                    trailing: Text('${r['rol']}'),
                  ),
              ]);
            },
          ),
      ],
    );
  }
}
