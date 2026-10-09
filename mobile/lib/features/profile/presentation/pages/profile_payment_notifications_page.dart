import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../domain/entities/payment_notification_entity.dart';
import '../providers/profile_providers.dart';

final myPaymentNotificationsProvider =
    FutureProvider.autoDispose<List<PaymentNotificationEntity>>((ref) {
  return ref.watch(walletRemoteProvider).myPaymentNotifications();
});

/// Ödeme bildirimlerim — durum, admin açıklaması ve itiraz (spec §84).
class ProfilePaymentNotificationsPage extends ConsumerWidget {
  const ProfilePaymentNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myPaymentNotificationsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Ödeme Bildirimlerim',
          subtitle: 'Durum, açıklama ve itiraz',
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Info(
              text: ApiException.userMessage(e),
              onRetry: () => ref.invalidate(myPaymentNotificationsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return _Info(
                  text: 'Henüz ödeme bildiriminiz yok.',
                  onRetry: () => ref.invalidate(myPaymentNotificationsProvider),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(myPaymentNotificationsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _PaymentCard(item: items[i]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends ConsumerWidget {
  const _PaymentCard({required this.item});

  final PaymentNotificationEntity item;

  Color _statusColor(String status) => switch (status) {
        'approved' => const Color(0xFF2ECC71),
        'corrected' => const Color(0xFF3498DB),
        'rejected' || 'cancelled' => const Color(0xFFE74C3C),
        'refunded' => const Color(0xFF9B59B6),
        _ => const Color(0xFFF1C40F),
      };

  Future<void> _dispute(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bizimle iletişime geç'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Sorunu açıklayın (en az 10 karakter)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (message == null || !context.mounted) return;
    if (message.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az 10 karakter yazın')),
      );
      return;
    }
    try {
      await ref
          .read(walletRemoteProvider)
          .disputePaymentNotification(item.id, message);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destek talebiniz açıldı — Destek Taleplerim’den takip edin'),
        ),
      );
      ref.invalidate(myPaymentNotificationsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  bool get _cancellable => item.status == 'pending' || item.status == 'corrected';

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bildirimi iptal et'),
        content: const Text(
          'Bu ödeme bildirimi iptal edilecek ve onaya gönderilmeyecek. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const ValueKey('payment-cancel-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İptal et'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(walletRemoteProvider).cancelPaymentNotification(item.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme bildirimi iptal edildi')),
      );
      ref.invalidate(myPaymentNotificationsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(item.status);
    final date = item.createdAt?.toLocal();
    final lines = [
      if (item.requestedSummary != null) 'Talep: ${item.requestedSummary}',
      if (item.loadedSummary != null) 'Yüklenen: ${item.loadedSummary}',
      if (item.paymentMethodLabel != null) 'Yöntem: ${item.paymentMethodLabel}',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.productLabel} · ${item.amount.toStringAsFixed(2)} TL',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 4),
            Text(
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          for (final l in lines) ...[
            const SizedBox(height: 4),
            Text(l, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (item.adminMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              item.adminMessage!,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          if (_cancellable) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: ValueKey('payment-cancel-${item.id}'),
                onPressed: () => _cancel(context, ref),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('İptal et'),
              ),
            ),
          ],
          if (item.hasDispute) ...[
            const SizedBox(height: 8),
            Text(
              'Destek talebi açık (${item.disputeStatus ?? 'açık'})',
              style: const TextStyle(color: Color(0xFF3498DB)),
            ),
          ] else if (item.canDispute) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _dispute(context, ref),
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: const Text('İtiraz et'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Yenile')),
          ],
        ),
      ),
    );
  }
}
