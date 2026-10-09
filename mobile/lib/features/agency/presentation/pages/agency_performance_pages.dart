import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/agency_management_models.dart';
import '../providers/agency_management_providers.dart';
import '../widgets/agency_mgmt_widgets.dart';

/// Ajans sahibi/yetkilisi: üyelerin doğrulanmış yayın performansı.
class AgencyPerformancePage extends ConsumerStatefulWidget {
  const AgencyPerformancePage({super.key});

  @override
  ConsumerState<AgencyPerformancePage> createState() => _AgencyPerformancePageState();
}

class _AgencyPerformancePageState extends ConsumerState<AgencyPerformancePage> {
  var _period = 'weekly';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agencyPerformanceProvider(_period));
    return Scaffold(
      appBar: AppBar(title: const Text('Yayıncı Performansı')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(agencyPerformanceProvider(_period).future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            PeriodChips(value: _period, onChanged: (p) => setState(() => _period = p)),
            const SizedBox(height: 10),
            AsyncSection<AgencyPerformanceReport>(
              value: async,
              onRetry: () => ref.invalidate(agencyPerformanceProvider(_period)),
              builder: (r) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatGrid(tiles: [
                    StatTile(label: 'Toplam doğrulanmış yayın', value: formatMinutes(r.totalMinutes), icon: Icons.videocam_rounded),
                    StatTile(label: 'Hedefi tutan', value: '${r.targetsMet} / ${r.targetsTotal}', icon: Icons.flag_rounded),
                    StatTile(label: 'Hediye (Jeton)', value: '${r.totalGiftJeton}', icon: Icons.card_giftcard_rounded),
                    StatTile(label: 'Üye', value: '${r.members.length}', icon: Icons.people_alt_rounded),
                  ]),
                  const SizedBox(height: 6),
                  Text('Yalnız canlı video yayını sayılır; çakışan yayınlar tek sayılır, medya kesilince sayım durur.',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SectionTitle('Yayıncılar'),
                  if (r.members.isEmpty) const Text('Üye yok.'),
                  for (final m in r.members)
                    UserRefTile(
                      key: Key('perf-row-${m.user.id}'),
                      user: m.user,
                      subtitle: '${formatMinutes(m.verifiedMinutes)} · ${m.activeDays} gün · ${m.sessionCount} yayın'
                          '${m.interruptedCount > 0 ? ' (${m.interruptedCount} kesinti)' : ''}'
                          '${m.giftJeton > 0 ? ' · ${m.giftJeton} Jeton hediye' : ''}',
                      trailing: m.targetMet == null
                          ? const Icon(Icons.chevron_right_rounded)
                          : Icon(
                              m.targetMet! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: m.targetMet! ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            ),
                      onTap: () => context.push('/ajans/performans/${m.user.id}'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek yayıncı: günlük dağılım, oturumlar, hedef, hak ediş, geçmiş, moderasyon.
class AgencyMemberPerformancePage extends ConsumerStatefulWidget {
  const AgencyMemberPerformancePage({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<AgencyMemberPerformancePage> createState() => _AgencyMemberPerformancePageState();
}

class _AgencyMemberPerformancePageState extends ConsumerState<AgencyMemberPerformancePage> {
  var _period = 'weekly';
  var _busy = false;

  (String, String) get _key => (widget.userId, _period);

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final msg = await action();
      if (mounted) showResult(context, msg);
      ref.invalidate(agencyMemberPerformanceProvider(_key));
      ref.invalidate(agencyAccrualsProvider);
    } catch (e) {
      if (mounted) showResult(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setTarget() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _TargetForm(),
    );
    if (result == null || !mounted) return;
    await _run(() => ref.read(agencyManagementProvider).setTarget(
          userId: widget.userId,
          period: result['period'] as String,
          targetMinutes: result['targetMinutes'] as int,
          minDays: result['minDays'] as int?,
          bonusJeton: result['bonusJeton'] as int,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agencyMemberPerformanceProvider(_key));
    return Scaffold(
      appBar: AppBar(
        title: Text(async.valueOrNull?.user?.display ?? 'Yayıncı'),
        actions: [
          IconButton(key: const Key('member-set-target'), tooltip: 'Hedef ata', onPressed: _busy ? null : _setTarget, icon: const Icon(Icons.flag_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(agencyMemberPerformanceProvider(_key).future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            PeriodChips(value: _period, onChanged: (p) => setState(() => _period = p)),
            const SizedBox(height: 10),
            AsyncSection<MemberPerformanceDetail>(
              value: async,
              onRetry: () => ref.invalidate(agencyMemberPerformanceProvider(_key)),
              builder: (d) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatGrid(tiles: [
                    StatTile(label: 'Doğrulanmış yayın', value: formatMinutes(d.verifiedMinutes), icon: Icons.videocam_rounded),
                    StatTile(label: 'Yayın yapılan gün', value: '${d.activeDays}', icon: Icons.calendar_month_rounded),
                    StatTile(label: 'Yayın / kesinti', value: '${d.sessionCount} / ${d.interruptedCount}', icon: Icons.wifi_tethering_error_rounded),
                    StatTile(label: 'Hediye (Jeton)', value: '${d.giftJeton}', icon: Icons.card_giftcard_rounded),
                  ]),
                  const SectionTitle('Günlük dağılım'),
                  DailyBars(daily: d.daily),
                  SectionTitle('Aktif hedefler (${d.targets.length})'),
                  if (d.targets.isEmpty) const Text('Hedef yok. Sağ üstten hedef atayabilirsiniz.'),
                  for (final t in d.targets)
                    TargetProgressCard(
                      target: t,
                      onClose: _busy
                          ? null
                          : () async {
                              if (!await confirmDialog(context, title: 'Hedefi kapat', body: 'Hedef kapanır; geçmiş kayıtlar korunur.', ok: 'Kapat')) return;
                              if (!mounted) return;
                              await _run(() => ref.read(agencyManagementProvider).closeTarget(t.id));
                            },
                    ),
                  SectionTitle('Hak edişler · ödenen ${d.bonusPaid} / bekleyen ${d.bonusEarned} Jeton'),
                  if (d.accruals.isEmpty) const Text('Kapanmış dönem yok.'),
                  for (final a in d.accruals) AccrualTile(accrual: a, busy: _busy, onPay: () => _pay(a), onVoid: () => _void(a)),
                  SectionTitle('Yayınlar (${d.sessions.length})'),
                  if (d.sessions.isEmpty) const Text('Bu aralıkta yayın yok.'),
                  for (final s in d.sessions)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        s.live ? Icons.sensors_rounded : s.interrupted ? Icons.wifi_off_rounded : Icons.videocam_outlined,
                        color: s.live ? const Color(0xFFEF4444) : s.interrupted ? const Color(0xFFF59E0B) : null,
                      ),
                      title: Text('${fmtDate(s.startedAt, time: true)} – ${s.live ? 'canlı' : fmtDate(s.endedAt, time: true)}'),
                      subtitle: Text('${formatMinutes(s.countedMinutes)} sayıldı${s.interrupted ? ' · kesinti' : ''}${s.title != null ? ' · ${s.title}' : ''}'),
                    ),
                  const SectionTitle('Ajans üyelik geçmişi'),
                  for (final h in d.history)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(h.agencyName),
                      subtitle: Text('${fmtDate(h.joinedAt)} – ${h.leftAt == null ? 'devam ediyor' : fmtDate(h.leftAt)}'
                          '${h.endedByLabel.isNotEmpty ? ' · ${h.endedByLabel}' : ''}'),
                    ),
                  SectionTitle('Moderasyon kayıtları (${d.moderation.length})'),
                  if (d.moderation.isEmpty) const Text('Bu aralıkta kayıt yok.'),
                  for (final m in d.moderation)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.gavel_rounded),
                      title: Text('${m.action} · ${m.severity ?? ''}'),
                      subtitle: Text('${m.kind} · ${fmtDate(m.createdAt, time: true)}'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pay(AccrualView a) async {
    if (!await confirmDialog(
      context,
      title: 'Bonusu öde',
      body: '${a.bonusJeton} Jeton ajans cüzdanından yayıncıya aktarılacak.',
      ok: 'Öde',
      okKey: const Key('accrual-pay-confirm'),
    )) {
      return;
    }
    if (!mounted) return;
    await _run(() => ref.read(agencyManagementProvider).payAccrual(a.id));
  }

  Future<void> _void(AccrualView a) async {
    final reason = await textInputDialog(context, title: 'Hak edişi iptal et', hint: 'Gerekçe (zorunlu)');
    if (reason == null || reason.length < 3 || !mounted) return;
    await _run(() => ref.read(agencyManagementProvider).voidAccrual(a.id, reason));
  }
}

class AccrualTile extends StatelessWidget {
  const AccrualTile({super.key, required this.accrual, required this.busy, this.onPay, this.onVoid, this.showUser = false});
  final AccrualView accrual;
  final bool busy;
  final VoidCallback? onPay;
  final VoidCallback? onVoid;
  final bool showUser;

  @override
  Widget build(BuildContext context) {
    final a = accrual;
    return Card(
      key: Key('accrual-${a.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${showUser && a.user != null ? '${a.user!.display} · ' : ''}${periodLabelTr(a.period)} · ${fmtDate(a.periodStart)} – ${fmtDate(a.periodEnd?.subtract(const Duration(seconds: 1)))}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('${formatMinutes(a.verifiedMinutes)} / ${formatMinutes(a.targetMinutes)} · ${a.statusLabel}'
                '${a.bonusJeton > 0 ? ' · ${a.bonusJeton} Jeton' : ''}'),
            if (a.payable && (onPay != null || onVoid != null))
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (onVoid != null) TextButton(onPressed: busy ? null : onVoid, child: const Text('İptal')),
                if (onPay != null) FilledButton(key: Key('accrual-pay-${a.id}'), onPressed: busy ? null : onPay, child: const Text('Öde')),
              ]),
          ],
        ),
      ),
    );
  }
}

class _TargetForm extends StatefulWidget {
  const _TargetForm();

  @override
  State<_TargetForm> createState() => _TargetFormState();
}

class _TargetFormState extends State<_TargetForm> {
  var _period = 'weekly';
  final _hours = TextEditingController();
  final _days = TextEditingController();
  final _bonus = TextEditingController(text: '0');
  String? _error;

  @override
  void dispose() {
    _hours.dispose();
    _days.dispose();
    _bonus.dispose();
    super.dispose();
  }

  void _submit() {
    final hours = double.tryParse(_hours.text.replaceAll(',', '.')) ?? 0;
    if (hours <= 0) return setState(() => _error = 'Hedef saat girin');
    Navigator.pop(context, {
      'period': _period,
      'targetMinutes': (hours * 60).round(),
      'minDays': int.tryParse(_days.text),
      'bonusJeton': int.tryParse(_bonus.text) ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Yayın hedefi ata', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final p in const ['daily', 'weekly', 'monthly'])
              ChoiceChip(label: Text(periodLabelTr(p)), selected: _period == p, onSelected: (_) => setState(() => _period = p)),
          ]),
          TextField(
            key: const Key('target-hours'),
            controller: _hours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Hedef (saat)', suffixText: 'saat'),
          ),
          TextField(
            controller: _days,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'En az yayın günü (isteğe bağlı)'),
          ),
          TextField(
            controller: _bonus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Hedef tutarsa bonus (Jeton)', suffixText: 'Jeton'),
          ),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 8),
          Text('Bonus, dönem kapandığında hedef tutarsa hak ediş olarak yazılır; ödeme ajans cüzdanından yapılır.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FilledButton(key: const Key('target-save'), onPressed: _submit, child: const Text('Kaydet')),
        ],
      ),
    );
  }
}
