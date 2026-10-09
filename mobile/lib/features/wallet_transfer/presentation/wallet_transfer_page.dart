import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../gifts/data/gift_idempotency.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../../search/domain/entities/search_user_entity.dart';
import '../../search/presentation/providers/search_providers.dart';
import '../data/wallet_transfer_remote.dart';

/// Hediye Yolla — kendi bakiyenden bir kullanıcıya Jeton veya CFC gönder.
/// Komisyon ve en az miktar admin panelinden gelir (`GET /api/wallet/transfer`).
class WalletTransferPage extends ConsumerStatefulWidget {
  const WalletTransferPage({super.key});

  @override
  ConsumerState<WalletTransferPage> createState() => _WalletTransferPageState();
}

class _WalletTransferPageState extends ConsumerState<WalletTransferPage> {
  final _search = TextEditingController();
  final _amount = TextEditingController();
  Timer? _debounce;
  List<SearchUserEntity> _results = const [];
  var _searching = false;
  SearchUserEntity? _recipient;
  var _currency = TransferCurrency.jeton;
  var _sending = false;
  String? _error;

  /// Aynı form gönderimi için tek anahtar — çift dokunma çift transfer olmaz.
  String _idempotencyKey = newGiftIdempotencyKey();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final list = await ref.read(searchRemoteProvider).searchUsers(q.trim());
      if (!mounted) return;
      setState(() => _results = list.take(8).toList());
    } catch (_) {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  int get _amountValue => int.tryParse(_amount.text.trim()) ?? 0;

  int _balanceOf(TransferCurrency c) {
    final b = ref.read(walletBalancesProvider).valueOrNull;
    if (b == null) return 0;
    return c == TransferCurrency.cfc ? b.cfc : b.jeton;
  }

  String? _validate(TransferRule rule) {
    if (_recipient == null) return 'Önce alıcı seçin';
    final a = _amountValue;
    if (a < rule.min) return 'En az ${rule.min} ${_currency.label} gönderebilirsiniz';
    if (a > _balanceOf(_currency)) return 'Yetersiz ${_currency.label} bakiyesi';
    return null;
  }

  Future<void> _send(TransferRule rule) async {
    final problem = _validate(rule);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final to = _recipient!;
    final amount = _amountValue;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hediyeyi onayla'),
        content: Text(
          '@${to.username} kişisine $amount ${_currency.label} gönderilecek.\n'
          'Komisyon: ${rule.commissionFor(amount)} (%${rule.commissionPercent})\n'
          'Alıcıya geçecek: ${rule.netFor(amount)} ${_currency.label}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('transfer-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final result = await ref.read(walletTransferRemoteProvider).send(
            recipient: to.id.isNotEmpty ? to.id : to.username,
            currency: _currency,
            amount: amount,
            idempotencyKey: _idempotencyKey,
          );
      _idempotencyKey = newGiftIdempotencyKey();
      // Bakiye yenilemesi başarısız olsa da transfer tamamlandı — hatayı yut.
      unawaited(
        ref.refreshWalletCache(force: true).catchError((Object _) {}),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _amount.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '@${to.username} kişisine ${result.received} ${_currency.label} gönderildi 🎁',
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is ApiException ? e.message : 'İşlem tamamlanamadı',
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(walletTransferRulesProvider).valueOrNull ??
        const TransferRules();
    final rule = rules.of(_currency);
    final balances = ref.watch(walletBalancesProvider).valueOrNull;
    final amount = _amountValue;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hediye Yolla')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('Kime?', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          if (_recipient == null) ...[
            TextField(
              key: const Key('transfer-search'),
              controller: _search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı ara',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            for (final u in _results)
              ListTile(
                key: Key('transfer-user-${u.id}'),
                contentPadding: EdgeInsets.zero,
                leading: UserAvatar(url: u.image, radius: 18),
                title: Text(u.name),
                subtitle: Text('@${u.username}'),
                onTap: () => setState(() {
                  _recipient = u;
                  _results = const [];
                  _error = null;
                }),
              ),
          ] else
            Card(
              child: ListTile(
                leading: UserAvatar(url: _recipient!.image, radius: 20),
                title: Text(_recipient!.name),
                subtitle: Text('@${_recipient!.username}'),
                trailing: IconButton(
                  tooltip: 'Değiştir',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _recipient = null),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text('Ne gönderilecek?', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          SegmentedButton<TransferCurrency>(
            segments: [
              ButtonSegment(
                value: TransferCurrency.jeton,
                icon: const Icon(Icons.toll_rounded),
                label: Text('Jeton (${balances?.jeton ?? 0})'),
              ),
              ButtonSegment(
                value: TransferCurrency.cfc,
                icon: const Icon(Icons.diamond_rounded),
                label: Text('CFC (${balances?.cfc ?? 0})'),
              ),
            ],
            selected: {_currency},
            onSelectionChanged: (s) => setState(() {
              _currency = s.first;
              _error = null;
            }),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const Key('transfer-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: 'Miktar',
              helperText: 'En az ${rule.min} ${_currency.label}',
              suffixText: _currency.label,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final q in [rule.min, rule.min * 5, rule.min * 10])
                ActionChip(
                  label: Text('$q'),
                  onPressed: () => setState(() {
                    _amount.text = '$q';
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (amount > 0)
            Text(
              'Komisyon: ${rule.commissionFor(amount)} (%${rule.commissionPercent}) · '
              'Alıcıya geçecek: ${rule.netFor(amount)} ${_currency.label}',
              key: const Key('transfer-summary'),
              style: theme.textTheme.bodyMedium,
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('transfer-send'),
            onPressed: _sending ? null : () => _send(rule),
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.card_giftcard_rounded),
            label: const Text('Hediye Gönder'),
          ),
        ],
      ),
    );
  }
}
