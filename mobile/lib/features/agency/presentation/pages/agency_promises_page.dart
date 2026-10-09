import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/agency_management_models.dart';
import '../providers/agency_management_providers.dart';
import '../widgets/agency_mgmt_widgets.dart';
import 'agencies_page.dart' show PromiseCard;

/// Ajans vaatleri — sahip taslak sürüm önerir, yönetici onaylayınca yayımlanır.
/// Onaylı sürüm değişmez; yeni şart için yeni sürüm gönderilir.
class AgencyPromisesPage extends ConsumerStatefulWidget {
  const AgencyPromisesPage({super.key});

  @override
  ConsumerState<AgencyPromisesPage> createState() => _AgencyPromisesPageState();
}

class _AgencyPromisesPageState extends ConsumerState<AgencyPromisesPage> {
  var _busy = false;

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final msg = await action();
      if (mounted) showResult(context, msg);
      ref.invalidate(agencyPromisesProvider);
    } catch (e) {
      if (mounted) showResult(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openForm(PromiseRules rules, {AgencyPromiseGroup? base}) async {
    final latest = base?.versions.isNotEmpty == true ? base!.versions.first : null;
    final fields = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => PromiseFormPage(rules: rules, base: latest, isNewVersion: base != null)),
    );
    if (fields == null || !mounted) return;
    final ds = ref.read(agencyManagementProvider);
    await _run(() => base == null ? ds.createPromise(fields) : ds.newPromiseVersion(base.id, fields));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agencyPromisesProvider);
    final data = async.valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Vaatler')),
      floatingActionButton: data != null && data.canEdit && data.rules.enabled
          ? FloatingActionButton.extended(
              key: const Key('promise-new'),
              onPressed: _busy ? null : () => _openForm(data.rules),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni vaat'),
            )
          : null,
      body: AsyncSection<AgencyPromisesData>(
        value: async,
        onRetry: () => ref.invalidate(agencyPromisesProvider),
        builder: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(agencyPromisesProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text(
                'Vaatler yalnız yönetici onayından sonra yayımlanır ve yayıncılara gösterilir. '
                'Onaylı sürüm değiştirilemez; yeni şartlar için yeni sürüm gönderin. '
                'Önceki sürümü kabul eden yayıncıların kayıtları korunur.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!d.rules.enabled) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Vaat sistemi yönetici tarafından kapatılmış.')),
              if (d.promises.isEmpty) const Padding(padding: EdgeInsets.only(top: 24), child: Center(child: Text('Henüz vaat yok.'))),
              for (final g in d.promises) ...[
                SectionTitle(
                  '${g.title}${g.status == 'archived' ? ' (arşiv)' : ''}',
                  trailing: d.canEdit && g.status != 'archived'
                      ? PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'version') {
                              await _openForm(d.rules, base: g);
                            } else if (v == 'archive') {
                              if (!await confirmDialog(context, title: 'Vaadi arşivle', body: 'Yeni üyelere gösterilmez; kabul kayıtları korunur.', ok: 'Arşivle')) return;
                              if (!mounted) return;
                              await _run(() => ref.read(agencyManagementProvider).archivePromise(g.id));
                            }
                          },
                          itemBuilder: (_) => [
                            if (!g.hasPending) const PopupMenuItem(value: 'version', child: Text('Yeni sürüm öner')),
                            const PopupMenuItem(value: 'archive', child: Text('Arşivle')),
                          ],
                        )
                      : null,
                ),
                for (final v in g.versions)
                  PromiseCard(
                    promise: v,
                    footer: Row(children: [
                      Chip(label: Text(v.statusLabel)),
                      const SizedBox(width: 8),
                      if (v.status == 'approved' || v.status == 'superseded') Text('${v.acceptedCount} kabul'),
                      const Spacer(),
                      if (v.status == 'pending' && d.canEdit)
                        TextButton(
                          onPressed: _busy ? null : () => _run(() => ref.read(agencyManagementProvider).withdrawPromiseVersion(v.id)),
                          child: const Text('Geri çek'),
                        ),
                    ]),
                  ),
                for (final v in g.versions.where((v) => v.status == 'rejected' && v.reviewNote != null))
                  Text('Sürüm ${v.version} ret gerekçesi: ${v.reviewNote}', style: const TextStyle(color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Vaat / yeni sürüm formu — sınırlar yönetici kurallarından.
class PromiseFormPage extends StatefulWidget {
  const PromiseFormPage({super.key, required this.rules, this.base, this.isNewVersion = false});
  final PromiseRules rules;
  final PromiseVersionView? base;
  final bool isNewVersion;

  @override
  State<PromiseFormPage> createState() => _PromiseFormPageState();
}

class _PromiseFormPageState extends State<PromiseFormPage> {
  late final _title = TextEditingController(text: widget.base?.title ?? '');
  late final _body = TextEditingController(text: widget.base?.body ?? '');
  late final _measurement = TextEditingController(text: widget.base?.measurement ?? '');
  late final _hours = TextEditingController(
    text: widget.base?.targetMinutes == null ? '' : (widget.base!.targetMinutes! / 60).toStringAsFixed(1),
  );
  late final _days = TextEditingController(text: widget.base?.minDays?.toString() ?? '');
  late final _bonus = TextEditingController(text: '${widget.base?.bonusJeton ?? 0}');
  late String _period = widget.base?.targetPeriod ?? widget.rules.allowedPeriods.first;
  var _reaccept = true;
  String? _error;

  @override
  void dispose() {
    for (final c in [_title, _body, _measurement, _hours, _days, _bonus]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final hours = double.tryParse(_hours.text.replaceAll(',', '.'));
    final minutes = hours == null || hours <= 0 ? null : (hours * 60).round();
    final bonus = int.tryParse(_bonus.text) ?? 0;
    if (!widget.isNewVersion && _title.text.trim().length < 3) return setState(() => _error = 'Başlık en az 3 karakter');
    if (_body.text.trim().length < 20) return setState(() => _error = 'Vaat metni en az 20 karakter olmalı');
    if (bonus > 0 && minutes == null) return setState(() => _error = 'Bonus için yayın hedefi girin');
    if (widget.rules.maxBonusJeton > 0 && bonus > widget.rules.maxBonusJeton) {
      return setState(() => _error = 'Bonus en fazla ${widget.rules.maxBonusJeton} Jeton');
    }
    if (minutes != null && widget.rules.maxTargetMinutes > 0 && minutes > widget.rules.maxTargetMinutes) {
      return setState(() => _error = 'Hedef en fazla ${formatMinutes(widget.rules.maxTargetMinutes)}');
    }
    Navigator.pop(context, {
      if (!widget.isNewVersion) 'title': _title.text.trim(),
      'body': _body.text.trim(),
      if (_measurement.text.trim().isNotEmpty) 'measurement': _measurement.text.trim(),
      if (minutes != null) ...{'targetPeriod': _period, 'targetMinutes': minutes},
      if (int.tryParse(_days.text) != null) 'minDays': int.parse(_days.text),
      'bonusJeton': bonus,
      'requiresReaccept': _reaccept,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isNewVersion ? 'Yeni sürüm' : 'Yeni vaat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!widget.isNewVersion)
            TextField(key: const Key('promise-title'), controller: _title, decoration: const InputDecoration(labelText: 'Başlık')),
          TextField(
            key: const Key('promise-body'),
            controller: _body,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Vaat ve yayıncı kabul şartları'),
          ),
          TextField(
            controller: _measurement,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Ölçüm açıklaması (boşsa standart metin)'),
          ),
          const SizedBox(height: 12),
          Text('Yayın hedefi (isteğe bağlı)', style: Theme.of(context).textTheme.titleSmall),
          Wrap(spacing: 8, children: [
            for (final p in widget.rules.allowedPeriods)
              ChoiceChip(label: Text(periodLabelTr(p)), selected: _period == p, onSelected: (_) => setState(() => _period = p)),
          ]),
          TextField(
            key: const Key('promise-hours'),
            controller: _hours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Hedef saat'),
          ),
          TextField(
            controller: _days,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'En az yayın günü'),
          ),
          TextField(
            controller: _bonus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Hedef bonusu (Jeton)',
              helperText: widget.rules.maxBonusJeton > 0 ? 'En fazla ${widget.rules.maxBonusJeton}' : null,
            ),
          ),
          if (widget.isNewVersion)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _reaccept,
              onChanged: (v) => setState(() => _reaccept = v),
              title: const Text('Mevcut üyelerden yeniden kabul iste'),
            ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
          const SizedBox(height: 16),
          FilledButton(key: const Key('promise-submit'), onPressed: _submit, child: const Text('Yönetici onayına gönder')),
          const SizedBox(height: 8),
          Text(
            'Vaatlerin hukuki bağlayıcılığı ayrıca değerlendirilmelidir; platform yalnız sürüm, kabul ve hak ediş kaydını tutar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
