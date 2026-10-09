import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../search/domain/entities/search_user_entity.dart';
import '../../../search/presentation/providers/search_providers.dart';
import '../../data/datasources/agency_wallet_datasource.dart';
import '../providers/agency_providers.dart';

final agencyWalletDataSourceProvider = Provider<AgencyWalletDataSource>(
  (ref) => AgencyWalletDataSource(ref.watch(dioProvider)),
);

final agencyPurchaseInfoProvider =
    FutureProvider.autoDispose.family<AgencyPurchaseInfo, int>((ref, jeton) {
  return ref.read(agencyWalletDataSourceProvider).fetchPurchase(jeton: jeton);
});

final _num = NumberFormat.decimalPattern('tr_TR');
final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

/// Ajans Jeton cüzdanı:
/// - Kullanıcıya Jeton Yükle: bakiye kadar, herhangi bir kullanıcıya; yüklenen
///   miktar tam düşer (komisyon yok). Yetmezse sunucu "X jeton eksik" der.
/// - Toplu Jeton Al: admin indirimiyle sipariş; ödeme onaylanınca cüzdana geçer.
/// Ajans ile kullanıcı arasındaki ücret platform dışındadır.
class AgencyWalletPage extends ConsumerWidget {
  const AgencyWalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(agencyWalletProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajans Cüzdanı'),
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('agency-tab-load'), text: 'Kullanıcıya Yükle'),
              Tab(key: Key('agency-tab-buy'), text: 'Toplu Jeton Al'),
            ],
          ),
        ),
        body: Column(
          children: [
            _BalanceHeader(
              wallet: walletAsync.valueOrNull,
              loading: walletAsync.isLoading,
              onRefresh: () => ref.invalidate(agencyWalletProvider),
            ),
            const Expanded(
              child: TabBarView(
                children: [_LoadUserTab(), _PurchaseTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.wallet, required this.loading, required this.onRefresh});

  final AgencyWalletSnapshot? wallet;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final w = wallet;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFFFC94D)),
        title: Text(
          loading && w == null ? 'Yükleniyor…' : '${_num.format((w?.jetonBalance ?? 0).floor())} Jeton',
          key: const Key('agency-wallet-balance'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        subtitle: Text(w?.isLocked == true ? 'Cüzdan kilitli — yönetici ile görüşün' : 'Ajans bakiyesi'),
        trailing: IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
      ),
    );
  }
}

// ── Kullanıcıya Jeton Yükle ─────────────────────────────────

class _LoadUserTab extends ConsumerStatefulWidget {
  const _LoadUserTab();

  @override
  ConsumerState<_LoadUserTab> createState() => _LoadUserTabState();
}

class _LoadUserTabState extends ConsumerState<_LoadUserTab> {
  final _search = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  Timer? _debounce;
  List<SearchUserEntity> _results = const [];
  var _searching = false;
  SearchUserEntity? _target;
  var _sending = false;
  String? _error;

  /// Aynı form gönderimi için tek anahtar — çift dokunma çift yükleme olmaz.
  String _key = const Uuid().v4();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(q));
  }

  Future<void> _run(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final list = await ref.read(searchRemoteProvider).searchUsers(q.trim());
      if (mounted) setState(() => _results = list.take(8).toList());
    } catch (_) {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  int get _value => int.tryParse(_amount.text.trim()) ?? 0;

  Future<void> _submit() async {
    final to = _target;
    final amount = _value;
    final balance = (ref.read(agencyWalletProvider).valueOrNull?.jetonBalance ?? 0).floor();
    if (to == null) return setState(() => _error = 'Önce kullanıcı seçin');
    if (amount <= 0) return setState(() => _error = 'Yüklenecek Jeton miktarını girin');
    if (amount > balance) {
      // Sunucu da aynı kontrolü yapar; burada kullanıcıya hemen söyleriz.
      return setState(() => _error = 'Ajans bakiyesi yetersiz: ${_num.format(amount - balance)} jeton eksik');
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yüklemeyi onayla'),
        content: Text(
          'Alıcı: @${to.username}\n'
          'Yüklenecek: ${_num.format(amount)} Jeton\n'
          'Yükleme sonrası ajans bakiyesi: ${_num.format(balance - amount)} Jeton',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            key: const Key('agency-load-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yükle'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final res = await ref.read(agencyWalletDataSourceProvider).transfer(
          targetUserId: to.id,
          amount: amount,
          reason: _note.text,
          idempotencyKey: _key,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (!res.ok) {
      setState(() => _error = res.message);
      return;
    }
    _key = const Uuid().v4();
    HapticFeedback.mediumImpact();
    _amount.clear();
    _note.clear();
    ref.invalidate(agencyWalletProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('@${to.username} hesabına ${_num.format(amount)} Jeton yüklendi')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text('Kime?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        if (_target == null) ...[
          TextField(
            key: const Key('agency-load-search'),
            controller: _search,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Kullanıcı adı ara',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
            ),
          ),
          for (final u in _results)
            ListTile(
              key: Key('agency-load-user-${u.id}'),
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(url: u.image, radius: 18),
              title: Text(u.name),
              subtitle: Text('@${u.username}'),
              onTap: () => setState(() {
                _target = u;
                _results = const [];
                _error = null;
              }),
            ),
        ] else
          Card(
            child: ListTile(
              leading: UserAvatar(url: _target!.image, radius: 20),
              title: Text(_target!.name),
              subtitle: Text('@${_target!.username}'),
              trailing: IconButton(
                tooltip: 'Değiştir',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() => _target = null),
              ),
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('agency-load-amount'),
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() => _error = null),
          decoration: const InputDecoration(labelText: 'Yüklenecek Jeton', suffixText: 'Jeton'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Not (isteğe bağlı)'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, key: const Key('agency-load-error'), style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('agency-load-send'),
          onPressed: _sending ? null : _submit,
          icon: _sending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send_rounded),
          label: const Text('Jeton Yükle'),
        ),
        const SizedBox(height: 12),
        Text(
          'Yüklenen miktar ajans bakiyesinden aynen düşer; komisyon kesilmez. '
          'Ajans ile kullanıcı arasındaki ödeme platform dışında yapılır.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ── Toplu Jeton Al ──────────────────────────────────────────

const _methods = <(String, String)>[
  ('bank_transfer', 'Havale / EFT'),
  ('papara', 'Papara'),
  ('whatsapp', 'WhatsApp ile'),
];

class _PurchaseTab extends ConsumerStatefulWidget {
  const _PurchaseTab();

  @override
  ConsumerState<_PurchaseTab> createState() => _PurchaseTabState();
}

class _PurchaseTabState extends ConsumerState<_PurchaseTab> {
  final _amount = TextEditingController(text: '100000');
  final _ref = TextEditingController();
  final _sender = TextEditingController();
  Timer? _debounce;
  var _quoteFor = 100000;
  var _method = 'bank_transfer';
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _amount.dispose();
    _ref.dispose();
    _sender.dispose();
    super.dispose();
  }

  void _onAmount(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final n = int.tryParse(v.trim()) ?? 0;
      if (n > 0 && mounted) setState(() => _quoteFor = n);
    });
    setState(() => _error = null);
  }

  Future<void> _order(AgencyPurchaseInfo info) async {
    final jeton = int.tryParse(_amount.text.trim()) ?? 0;
    if (jeton < info.minJeton) {
      return setState(() => _error = 'En az ${_num.format(info.minJeton)} Jeton alınabilir');
    }
    final q = info.quote;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Siparişi onayla'),
        content: Text(
          '${_num.format(jeton)} Jeton\n'
          'Ödenecek: ${_tl.format(q.jetonAmount == jeton ? q.finalPriceTl : 0)}\n\n'
          'Ödemeyi yaptıktan sonra siparişi gönderin. Yönetici ödemeyi onaylayınca '
          'Jetonlar ajans cüzdanına yüklenir.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            key: const Key('agency-buy-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(agencyWalletDataSourceProvider).createPurchase(
            jeton: jeton,
            paymentMethod: _method,
            transactionId: _ref.text,
            senderName: _sender.text,
          );
      if (!mounted) return;
      _ref.clear();
      ref.invalidate(agencyPurchaseInfoProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş gönderildi — ödeme onayı bekleniyor')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Sipariş gönderilemedi');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(AgencyPurchaseOrder o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Siparişi iptal et'),
        content: Text('${_num.format(o.jeton)} Jeton · ${_tl.format(o.amountTl)} siparişi iptal edilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('İptal et')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(agencyWalletDataSourceProvider).cancelPaymentNotification(o.id, reason: 'Ajans iptal etti');
      ref.invalidate(agencyPurchaseInfoProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'İptal edilemedi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(agencyPurchaseInfoProvider(_quoteFor));
    final theme = Theme.of(context);
    return infoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e is ApiException ? e.message : 'Satın alma bilgisi yüklenemedi', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(agencyPurchaseInfoProvider),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
      data: (info) {
        final q = info.quote;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (!info.enabled)
              const Card(child: ListTile(title: Text('Toplu Jeton alımı şu anda kapalı'))),
            TextField(
              key: const Key('agency-buy-amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _onAmount,
              decoration: InputDecoration(
                labelText: 'Alınacak Jeton',
                helperText: 'En az ${_num.format(info.minJeton)} Jeton',
                suffixText: 'Jeton',
              ),
            ),
            const SizedBox(height: 12),
            Card(
              key: const Key('agency-buy-quote'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _row('Jeton', '${_num.format(q.jetonAmount)} Jeton'),
                    _row('Normal fiyat', _tl.format(q.normalPriceTl), strike: q.savedTl > 0),
                    if (q.discountPercent > 0) _row('Ajans indirimi', '%${q.discountPercent.toStringAsFixed(q.discountPercent % 1 == 0 ? 0 : 1)}'),
                    const Divider(),
                    _row('Ödenecek tutar', _tl.format(q.finalPriceTl), bold: true),
                    if (q.savedTl > 0) _row('Kazancınız', _tl.format(q.savedTl)),
                    const SizedBox(height: 4),
                    Text(
                      'Cüzdana yüklenecek: ${_num.format(q.jetonAmount)} Jeton',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final m in _methods)
                  ChoiceChip(
                    label: Text(m.$2),
                    selected: _method == m.$1,
                    onSelected: (_) => setState(() => _method = m.$1),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sender,
              decoration: const InputDecoration(labelText: 'Gönderen adı (isteğe bağlı)'),
            ),
            TextField(
              controller: _ref,
              decoration: const InputDecoration(labelText: 'Dekont / işlem no (isteğe bağlı)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, key: const Key('agency-buy-error'), style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('agency-buy-send'),
              onPressed: _busy || !info.enabled || q.jetonAmount != (int.tryParse(_amount.text.trim()) ?? 0)
                  ? null
                  : () => _order(info),
              icon: const Icon(Icons.shopping_bag_rounded),
              label: const Text('Ödeme bildirimi gönder'),
            ),
            const SizedBox(height: 24),
            Text('Siparişlerim', style: theme.textTheme.titleSmall),
            if (info.orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Henüz sipariş yok.'),
              ),
            for (final o in info.orders)
              ListTile(
                key: Key('agency-order-${o.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text('${_num.format(o.jeton)} Jeton · ${_tl.format(o.amountTl)}'),
                subtitle: Text(o.statusLabel),
                trailing: o.cancellable
                    ? TextButton(onPressed: () => _cancel(o), child: const Text('İptal'))
                    : null,
              ),
          ],
        );
      },
    );
  }

  Widget _row(String k, String v, {bool bold = false, bool strike = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(k)),
            Text(
              v,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                decoration: strike ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      );
}
