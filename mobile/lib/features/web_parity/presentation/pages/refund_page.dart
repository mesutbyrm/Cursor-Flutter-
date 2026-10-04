import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../domain/parity_models.dart';
import '../providers/parity_providers.dart';
import '../widgets/parity_widgets.dart';

/// İade taleplerim + yeni talep — `GET/POST /api/refunds`.
class RefundPage extends ConsumerWidget {
  const RefundPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refunds = ref.watch(refundsProvider);
    return MockScaffold(
      title: 'İade talepleri',
      actions: [
        IconButton(
          tooltip: 'Yeni iade talebi',
          icon: const Icon(Icons.add_rounded),
          onPressed: () => _openForm(context, ref),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(refundsProvider.future),
        child: ParityAsync<List<RefundRequest>>(
          value: refunds,
          onRetry: () => ref.invalidate(refundsProvider),
          isEmpty: (d) => d.isEmpty,
          emptyIcon: Icons.currency_exchange_rounded,
          emptyText: 'İade talebin yok.\nSağ üstteki + ile talep oluştur.',
          builder: (list) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = list[i];
              final color = switch (r.status) {
                'approved' || 'processed' => const Color(0xFF22C55E),
                'rejected' => const Color(0xFFEF4444),
                _ => const Color(0xFFF59E0B),
              };
              return ParityCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${r.amount.toStringAsFixed(2)} ${r.currency}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        ParityChip(RefundRequest.statusLabel(r.status), color: color),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(r.reason, style: const TextStyle(fontSize: 13, height: 1.35)),
                    if ((r.adminNote ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Not: ${r.adminNote}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      parityDateLabel(r.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _RefundForm(),
    );
    if (done == true) ref.invalidate(refundsProvider);
  }
}

class _RefundForm extends ConsumerStatefulWidget {
  const _RefundForm();

  @override
  ConsumerState<_RefundForm> createState() => _RefundFormState();
}

class _RefundFormState extends ConsumerState<_RefundForm> {
  final _ref = TextEditingController();
  final _reason = TextEditingController();
  var _store = false;
  var _busy = false;

  @override
  void dispose() {
    _ref.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = _ref.text.trim();
    final reason = _reason.text.trim();
    if (id.isEmpty) {
      parityToast(context, 'Ödeme / satın alma kimliği gerekli');
      return;
    }
    if (reason.length < 5) {
      parityToast(context, 'İade nedeni en az 5 karakter olmalı');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(parityApiProvider).createRefund(
            referenceId: id,
            reason: reason,
            storePurchase: _store,
          );
      if (!mounted) return;
      parityToast(context, 'İade talebin alındı');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'İade talebi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Web ödemesi')),
              ButtonSegment(value: true, label: Text('Mağaza satın alımı')),
            ],
            selected: {_store},
            onSelectionChanged: (v) => setState(() => _store = v.first),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ref,
            decoration: InputDecoration(
              labelText: _store ? 'Satın alma kimliği' : 'Ödeme kimliği',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reason,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'İade nedeni',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : () => unawaited(_submit()),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Talebi gönder'),
          ),
          const SizedBox(height: 6),
          Text(
            'Gerçek para iadesi manuel incelenir; sonuç bu listede görünür.',
            style: TextStyle(fontSize: 11.5, color: context.colors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
