import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/agency_management_models.dart';
import '../providers/agency_management_providers.dart';
import '../widgets/agency_mgmt_widgets.dart';

const _sorts = <(String, String)>[
  ('recommended', 'Önerilen'),
  ('hours', 'Yayın saati'),
  ('members', 'Yayıncı sayısı'),
  ('success', 'Hedef başarısı'),
  ('level', 'Seviye'),
  ('newest', 'En yeni'),
];

/// Ajanslar keşif sayfası — sıralama ve istatistikler sunucudan, gerçek verilerle.
class AgenciesPage extends ConsumerStatefulWidget {
  const AgenciesPage({super.key});

  @override
  ConsumerState<AgenciesPage> createState() => _AgenciesPageState();
}

class _AgenciesPageState extends ConsumerState<AgenciesPage> {
  var _sort = 'recommended';
  var _query = '';
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = (_sort, _query);
    final async = ref.watch(agenciesListProvider(key));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajanslar'),
        actions: [
          IconButton(
            key: const Key('agencies-my-panel'),
            tooltip: 'Yayıncı panelim',
            onPressed: () => context.push('/ajans/yayinci'),
            icon: const Icon(Icons.badge_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(agenciesListProvider(key).future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextField(
              key: const Key('agencies-search'),
              controller: _search,
              onChanged: _onSearch,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Ajans ara'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final s in _sorts)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: Key('agencies-sort-${s.$1}'),
                        label: Text(s.$2),
                        selected: _sort == s.$1,
                        onSelected: (_) => setState(() => _sort = s.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Yayın saati son 30 gündeki doğrulanmış video yayınıdır. Hedef başarısı son 90 günde kapanmış dönemlerden hesaplanır.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            AsyncSection<List<AgencyCard>>(
              value: async,
              onRetry: () => ref.invalidate(agenciesListProvider(key)),
              isEmpty: (l) => l.isEmpty,
              emptyText: _query.isEmpty ? 'Henüz listelenen ajans yok.' : '"$_query" ile eşleşen ajans yok.',
              builder: (list) => Column(
                children: [for (var i = 0; i < list.length; i++) _AgencyCardTile(card: list[i], rank: i + 1)],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/ajans/basvur'),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Kendi ajansını kur'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgencyCardTile extends StatelessWidget {
  const _AgencyCardTile({required this.card, required this.rank});
  final AgencyCard card;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final c = card;
    final rate = c.targetSuccessRate;
    return Card(
      key: Key('agency-card-${c.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/ajanslar/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(url: c.logoUrl, radius: 26),
                  Positioned(
                    left: -6,
                    top: -6,
                    child: CircleAvatar(radius: 11, child: Text('$rank', style: const TextStyle(fontSize: 11))),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16), overflow: TextOverflow.ellipsis)),
                      if (c.verified) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified_rounded, size: 18, color: Color(0xFF3B82F6))),
                      if (c.featured) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B))),
                    ]),
                    Text('${c.levelLabel} seviye', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Metric(icon: Icons.people_alt_rounded, text: '${c.activeMembers} yayıncı'),
                        _Metric(icon: Icons.videocam_rounded, text: '${c.verifiedHours30d.toStringAsFixed(1)} sa / 30 gün'),
                        _Metric(icon: Icons.flag_rounded, text: rate == null ? 'Hedef verisi yok' : '%${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)} hedef başarısı'),
                        if (c.activePromises > 0) _Metric(icon: Icons.handshake_rounded, text: '${c.activePromises} vaat'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 4),
      Text(text, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

/// Ajans detayı: istatistik, yayımlanmış vaatler (yayıncı kabul şartları,
/// hedef ve bonus kuralları), üyeler ve başvuru.
class AgencyDetailPage extends ConsumerStatefulWidget {
  const AgencyDetailPage({super.key, required this.agencyId});
  final String agencyId;

  @override
  ConsumerState<AgencyDetailPage> createState() => _AgencyDetailPageState();
}

class _AgencyDetailPageState extends ConsumerState<AgencyDetailPage> {
  var _busy = false;

  Future<void> _apply() async {
    final message = await textInputDialog(
      context,
      title: 'Ajansa başvur',
      hint: 'Kendinizi kısaca tanıtın (isteğe bağlı)',
      fieldKey: const Key('agency-apply-message'),
    );
    if (message == null || !mounted) return;
    await _run(() => ref.read(agencyManagementProvider).applyToAgency(widget.agencyId, message: message));
  }

  Future<void> _withdraw() async {
    if (!await confirmDialog(context, title: 'Başvuruyu geri çek', body: 'Bekleyen başvurunuz geri çekilecek.', ok: 'Geri çek')) return;
    await _run(() => ref.read(agencyManagementProvider).withdrawApplication(widget.agencyId));
  }

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final msg = await action();
      if (mounted) showResult(context, msg);
      ref.invalidate(agencyDetailProvider(widget.agencyId));
    } catch (e) {
      if (mounted) showResult(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agencyDetailProvider(widget.agencyId));
    return Scaffold(
      appBar: AppBar(title: Text(async.valueOrNull?.card.name ?? 'Ajans')),
      body: AsyncSection<AgencyDetail>(
        value: async,
        onRetry: () => ref.invalidate(agencyDetailProvider(widget.agencyId)),
        builder: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(agencyDetailProvider(widget.agencyId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(children: [
                UserAvatar(url: d.card.logoUrl, radius: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.card.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text('${d.card.levelLabel} seviye${d.owner != null ? ' · Sahibi: ${d.owner!.display}' : ''}'),
                  ]),
                ),
              ]),
              if (d.card.description != null) ...[const SizedBox(height: 12), Text(d.card.description!)],
              const SizedBox(height: 14),
              StatGrid(tiles: [
                StatTile(label: 'Aktif yayıncı', value: '${d.card.activeMembers}', icon: Icons.people_alt_rounded),
                StatTile(label: 'Yayın (30 gün)', value: '${d.card.verifiedHours30d.toStringAsFixed(1)} sa', icon: Icons.videocam_rounded),
                StatTile(
                  label: 'Hedef başarısı (90 gün)',
                  value: d.card.targetSuccessRate == null ? 'Veri yok' : '%${d.card.targetSuccessRate!.toStringAsFixed(1)}',
                  icon: Icons.flag_rounded,
                ),
                StatTile(label: 'Kapanan hedef dönemi', value: '${d.card.closedTargets90d}', icon: Icons.event_available_rounded),
              ]),
              const SizedBox(height: 14),
              _RelationAction(relation: d.relation, accepts: d.acceptsApplications, busy: _busy, onApply: _apply, onWithdraw: _withdraw),
              SectionTitle('Vaatler ve yayıncı şartları (${d.promises.length})'),
              if (d.promises.isEmpty)
                const Text('Bu ajansın yönetici onaylı vaadi yok.')
              else
                for (final p in d.promises) PromiseCard(promise: p),
              if (d.members.isNotEmpty) ...[
                const SectionTitle('Yayıncılar'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final m in d.members)
                      SizedBox(
                        width: 64,
                        child: Column(children: [
                          UserAvatar(url: m.image, radius: 22),
                          const SizedBox(height: 4),
                          Text(m.username ?? m.display, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                        ]),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RelationAction extends StatelessWidget {
  const _RelationAction({required this.relation, required this.accepts, required this.busy, required this.onApply, required this.onWithdraw});
  final AgencyRelation relation;
  final bool accepts;
  final bool busy;
  final VoidCallback onApply;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final r = relation;
    if (!r.loggedIn) return const Text('Başvurmak için giriş yapın.');
    if (r.isMember) {
      return FilledButton.icon(
        key: const Key('agency-detail-panel'),
        onPressed: () => context.push('/ajans/yayinci'),
        icon: const Icon(Icons.badge_rounded),
        label: const Text('Bu ajansın üyesisiniz · Yayıncı panelim'),
      );
    }
    if (r.pendingInviteId != null) {
      return FilledButton.icon(
        onPressed: () => context.push('/ajans/davetler'),
        icon: const Icon(Icons.mail_rounded),
        label: const Text('Bu ajanstan davetiniz var · Görüntüle'),
      );
    }
    if (r.pendingRequestId != null) {
      return OutlinedButton.icon(
        key: const Key('agency-detail-withdraw'),
        onPressed: busy ? null : onWithdraw,
        icon: const Icon(Icons.hourglass_top_rounded),
        label: const Text('Başvurunuz bekliyor · Geri çek'),
      );
    }
    if (r.inOtherAgency) return const Text('Başka bir ajansa üyesiniz. Başvurmak için önce ayrılmalısınız.');
    if (!accepts) return const Text('Bu ajans şu anda yeni üye kabul etmiyor.');
    return FilledButton.icon(
      key: const Key('agency-detail-apply'),
      onPressed: busy || !r.canApply ? null : onApply,
      icon: const Icon(Icons.how_to_reg_rounded),
      label: const Text('Ajansa başvur'),
    );
  }
}

/// Vaat sürümü kartı (keşif, yayıncı paneli ve ajans vaatleri sayfasında ortak).
class PromiseCard extends StatelessWidget {
  const PromiseCard({super.key, required this.promise, this.footer});
  final PromiseVersionView promise;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = promise;
    return Card(
      key: Key('promise-${p.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(p.title.isEmpty ? 'Vaat' : p.title, style: const TextStyle(fontWeight: FontWeight.w800))),
              Text('Sürüm ${p.version}', style: Theme.of(context).textTheme.bodySmall),
            ]),
            if (p.targetSummary != null) ...[
              const SizedBox(height: 6),
              Text(p.targetSummary!, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 8),
            Text(p.body),
            const SizedBox(height: 8),
            Text('Nasıl ölçülür: ${p.measurement}', style: Theme.of(context).textTheme.bodySmall),
            Text(
              'Geçerlilik: ${fmtDate(p.periodStart)} – ${p.periodEnd == null ? 'süresiz' : fmtDate(p.periodEnd)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (footer != null) ...[const SizedBox(height: 10), footer!],
          ],
        ),
      ),
    );
  }
}
