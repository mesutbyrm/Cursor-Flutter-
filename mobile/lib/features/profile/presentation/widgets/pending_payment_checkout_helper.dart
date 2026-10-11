import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../providers/payment_requests_notifier.dart';
import '../providers/profile_providers.dart';

/// POST öncesi — bekleyen talep varsa diyalog; iptal sonrası devam edilebilir.
Future<bool> guardCheckoutNoPendingPayment(
  BuildContext context,
  WidgetRef ref,
) async {
  final wallet = ref.read(walletRepositoryProvider);
  final pending = await wallet.fetchActivePendingPaymentRequest();
  if (pending == null) return true;

  final choice = await showDialog<_PendingConflictChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Bekleyen ödeme talebi'),
      content: Text(
        '${pending.displayLine}\n\n'
        'Yeni talep göndermek için önce bekleyen talebi iptal edin.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _PendingConflictChoice.wait),
          child: const Text('Onay bekle'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(ctx, _PendingConflictChoice.cancelAndRetry),
          child: const Text('İptal et ve devam et'),
        ),
      ],
    ),
  );
  if (choice != _PendingConflictChoice.cancelAndRetry) return false;
  try {
    await ref
        .read(paymentRequestsNotifierProvider.notifier)
        .cancelPending(pending.id);
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
    return false;
  }
}

/// 409 / `PENDING_PAYMENT_EXISTS` — iptal edip yeniden dene akışı.
Future<bool> handlePendingPaymentCheckoutConflict(
  BuildContext context,
  WidgetRef ref, {
  required Future<void> Function() retrySubmit,
}) async {
  final wallet = ref.read(walletRepositoryProvider);
  final pending = await wallet.fetchActivePendingPaymentRequest();
  final choice = await showDialog<_PendingConflictChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Bekleyen ödeme talebi'),
      content: Text(
        pending != null
            ? '${pending.displayLine}\n\n'
                'Yeni talep göndermek için önce bekleyen talebi iptal edin.'
            : 'Zaten bekleyen bir ödeme talebiniz var. '
                'İptal edip yeni talep oluşturabilir veya onay bekleyebilirsiniz.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _PendingConflictChoice.wait),
          child: const Text('Onay bekle'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _PendingConflictChoice.cancelAndRetry),
          child: const Text('İptal et ve yeniden dene'),
        ),
      ],
    ),
  );
  if (choice != _PendingConflictChoice.cancelAndRetry) return false;
  try {
    if (pending != null) {
      await ref
          .read(paymentRequestsNotifierProvider.notifier)
          .cancelPending(pending.id);
    }
    await retrySubmit();
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
    return false;
  }
}

bool isPendingPaymentConflict(Object e) {
  if (e is ApiException) {
    if (e.errorCode == 'PENDING_PAYMENT_EXISTS') return true;
    final code = e.statusCode ?? 0;
    if (code == 409) return true;
    final msg = e.message.toLowerCase();
    return msg.contains('bekleyen') && msg.contains('talep');
  }
  return false;
}

enum _PendingConflictChoice { wait, cancelAndRetry }
