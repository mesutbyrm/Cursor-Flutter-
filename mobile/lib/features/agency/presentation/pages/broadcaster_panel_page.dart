import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/agency_management_models.dart';
import '../providers/agency_management_providers.dart';
import '../widgets/agency_mgmt_widgets.dart';
import 'agencies_page.dart' show PromiseCard;

/// Yayıncı paneli — ajansa bağlı kullanıcının kendi verisi.
class BroadcasterPanelPage extends ConsumerStatefulWidget {
  const BroadcasterPanelPage({super.key});

  @override
  ConsumerState<BroadcasterPanelPage> createState() => _BroadcasterPanelPageState();
}

class _BroadcasterPanelPageState extends ConsumerState<BroadcasterPanelPage> {
  var _busy = false;

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final msg = await action();
      if (mounted) showResult(context, msg);
      ref.invalidate(broadcasterPanelProvider);
    } catch (e) {
      if (mounted) showResult(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(PromiseVersionView p) async {
    final ok = await confirmDialog(
      context,
      title: '"${p.title}" — sürüm ${p.version}',
      body: '${p.body}\n\n'
          '${p.targetSummary != null ? 'Hedef: ${p.targetSummary}\n\n' : ''}'
          'Nasıl ölçülür: ${p.measurement}\n\n'
          'Kabul ettiğinizde sürüm, tarih ve hesabınız kayıt altına alınır.',
      ok: 'Okudum, kabul ediyorum',
      okKey: const Key('promise-accept-confirm'),
    );
    if (!ok) return;
    await _run(() => ref.read(agencyManagementProvider).acceptPromise(p.id));
  }

  Future<void> _leave(BroadcasterPanel d) async {
    if (d.pendingLeave) {
      if (!await confirmDialog(context, title: 'Ayrılma talebini iptal et', body: 'Bekleyen ayrılma talebiniz geri çekilecek.', ok: 'İptal et')) return;
      if (!mounted) return;
      await _run(() => ref.read(agencyManagementProvider).cancelLeave());
      return;
    }
    final reason = await textInputDialog(context, title: 'Ajanstan ayrıl', hint: 'Gerekçe (isteğe bağlı)\n${d.rules['leave'] ?? ''}');
    if (reason == null || !mounted) return;
    await _run(() => ref.read(agencyManagementProvider).requestLeave(reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(broadcasterPanelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Yayıncı Paneli')),
      body: AsyncSection<BroadcasterPanel>(
        value: async,
        onRetry: () => ref.invalidate(broadcasterPanelProvider),
        builder: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(broadcasterPanelProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: d.hasAgency ? _member(context, d) : _noAgency(context, d),
          ),
        ),
      ),
    );
  }

  List<Widget> _noAgency(BuildContext context, BroadcasterPanel d) => [
        const InfoState(icon: Icons.apartment_rounded, text: 'Bir ajansa bağlı değilsiniz.'),
        FilledButton.icon(
          key: const Key('broadcaster-find-agency'),
          onPressed: () => context.push('/ajanslar'),
          icon: const Icon(Icons.search_rounded),
          label: const Text('Ajansları keşfet'),
        ),
        ..._history(context, d),
      ];

  List<Widget> _member(BuildContext context, BroadcasterPanel d) {
    final pending = d.promises.where((p) => p.needsAcceptance).toList();
    return [
      Card(
        child: ListTile(
          leading: UserAvatar(url: d.agencyLogo, radius: 22),
          title: Text(d.agencyName ?? 'Ajans', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${d.isOwner ? 'Sahip' : d.role == 'manager' ? 'Yönetici' : 'Yayıncı'} · katılım ${fmtDate(d.joinedAt)}'
              '${d.pendingLeave ? '\nAyrılma talebiniz bekliyor' : ''}'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/ajanslar/${d.agencyId}'),
        ),
      ),
      if (pending.isNotEmpty)
        Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: ListTile(
            leading: const Icon(Icons.assignment_late_rounded),
            title: Text('${pending.length} vaat onayınızı bekliyor'),
            subtitle: const Text('Aşağıdaki şartları okuyup kabul edebilirsiniz.'),
          ),
        ),
      const SectionTitle('Doğrulanmış yayın süresi'),
      StatGrid(tiles: [
        for (final p in const ['daily', 'weekly', 'monthly'])
          StatTile(
            label: p == 'daily' ? 'Bugün' : p == 'weekly' ? 'Bu hafta' : 'Bu ay',
            value: '${formatMinutes(d.totals[p]?.$1 ?? 0)} · ${d.totals[p]?.$2 ?? 0} gün',
            icon: Icons.videocam_rounded,
          ),
        StatTile(label: 'Bonus (ödenen / bekleyen)', value: '${d.bonusPaid} / ${d.bonusEarned} Jeton', icon: Icons.toll_rounded),
      ]),
      Text(d.rules['measurement'] ?? '', style: Theme.of(context).textTheme.bodySmall),
      SectionTitle('Hedeflerim (${d.targets.length})'),
      if (d.targets.isEmpty) const Text('Ajansınız henüz hedef tanımlamadı.') else for (final t in d.targets) TargetProgressCard(target: t),
      SectionTitle('Vaatler (${d.promises.length})'),
      if (d.promises.isEmpty)
        const Text('Ajansınızın yayımlanmış vaadi yok.')
      else
        for (final p in d.promises)
          PromiseCard(
            promise: p,
            footer: p.needsAcceptance
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (p.previouslyAcceptedVersion != null)
                      Text('Sürüm ${p.previouslyAcceptedVersion} kabulünüz kayıtlı; şartlar güncellendi.', style: Theme.of(context).textTheme.bodySmall),
                    FilledButton(
                      key: Key('promise-accept-${p.id}'),
                      onPressed: _busy ? null : () => _accept(p),
                      child: const Text('Şartları oku ve kabul et'),
                    ),
                  ])
                : Text('✓ ${fmtDate(p.acceptedAt, time: true)} tarihinde kabul ettiniz', style: const TextStyle(color: Color(0xFF22C55E))),
          ),
      if (d.acceptedHistory.isNotEmpty) ...[
        const SectionTitle('Kabul geçmişi'),
        for (final a in d.acceptedHistory)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history_edu_rounded),
            title: Text('${a.$1} · sürüm ${a.$2 ?? '-'}'),
            subtitle: Text(fmtDate(a.$3, time: true)),
          ),
      ],
      SectionTitle('Bonus ve hak edişler (${d.accruals.length})'),
      if (d.accruals.isEmpty)
        const Text('Henüz kapanmış hedef dönemi yok.')
      else
        for (final a in d.accruals)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${periodLabelTr(a.period)} · ${fmtDate(a.periodStart)}'),
            subtitle: Text('${formatMinutes(a.verifiedMinutes)} / ${formatMinutes(a.targetMinutes)} · ${a.statusLabel}'),
            trailing: a.bonusJeton > 0 ? Text('${a.bonusJeton} Jeton') : null,
          ),
      SectionTitle('Ajans duyuruları (${d.announcements.length})'),
      if (d.announcements.isEmpty)
        const Text('Duyuru yok.')
      else
        for (final a in d.announcements)
          Card(
            child: ListTile(
              leading: Icon(a.pinned ? Icons.push_pin_rounded : Icons.campaign_rounded),
              title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${a.body}\n${fmtDate(a.createdAt, time: true)}'),
            ),
          ),
      ..._history(context, d),
      const SectionTitle('Kurallar'),
      for (final k in const ['singleAgency', 'leave', 'rights'])
        if (d.rules[k] != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• ${d.rules[k]}')),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => context.push('/destek/yeni'),
        icon: const Icon(Icons.support_agent_rounded),
        label: const Text('Destek / itiraz talebi'),
      ),
      if (!d.isOwner) ...[
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('broadcaster-leave'),
          onPressed: _busy ? null : () => _leave(d),
          icon: const Icon(Icons.logout_rounded),
          label: Text(d.pendingLeave ? 'Ayrılma talebini iptal et' : 'Ajanstan ayrılma talebi'),
        ),
      ],
    ];
  }

  List<Widget> _history(BuildContext context, BroadcasterPanel d) => [
        if (d.history.isNotEmpty) ...[
          const SectionTitle('Ajans geçmişim'),
          for (final h in d.history)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(h.leftAt == null ? Icons.circle : Icons.circle_outlined, size: 12, color: h.leftAt == null ? const Color(0xFF22C55E) : null),
              title: Text(h.agencyName),
              subtitle: Text('${fmtDate(h.joinedAt)} – ${h.leftAt == null ? 'devam ediyor' : fmtDate(h.leftAt)}'
                  '${h.endedByLabel.isNotEmpty ? ' · ${h.endedByLabel}' : ''}'),
            ),
        ],
        if (d.joinRequests.isNotEmpty || d.invites.isNotEmpty) ...[
          const SectionTitle('Başvuru ve davetlerim'),
          for (final r in d.joinRequests)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.outbox_rounded),
              title: Text('Başvuru: ${r.agencyName ?? 'Ajans'}'),
              subtitle: Text('${r.statusLabel} · ${fmtDate(r.createdAt)}'),
            ),
          for (final i in d.invites)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline_rounded),
              title: Text('Davet: ${i.$1}'),
              subtitle: Text('${switch (i.$2) {
                'pending' => 'Bekliyor',
                'accepted' => 'Kabul edildi',
                'rejected' => 'Reddedildi',
                'cancelled' => 'İptal',
                'expired' => 'Süresi doldu',
                _ => i.$2,
              }} · ${fmtDate(i.$3)}'),
            ),
        ],
      ];
}
