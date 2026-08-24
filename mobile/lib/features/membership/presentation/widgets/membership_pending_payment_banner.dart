import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/payment_requests_notifier.dart';
import '../../../profile/presentation/widgets/pending_payment_banner.dart';

/// Bekleyen üyelik ödeme talebi — cüzdan, görevler ve profil hub.
class MembershipPendingPaymentBanner extends ConsumerWidget {
  const MembershipPendingPaymentBanner({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref
            .watch(paymentRequestsNotifierProvider)
            .valueOrNull
            ?.where((r) => r.isMembershipCheckout && r.isPending)
            .toList() ??
        const [];
    if (pending.isEmpty) return const SizedBox.shrink();

    final first = pending.first;
    return Padding(
      padding: padding,
      child: PendingPaymentBanner(
        request: first,
        kind: first.isJeton ? PendingPaymentKind.jeton : PendingPaymentKind.cfc,
        totalPending: pending.length,
      ),
    );
  }
}
