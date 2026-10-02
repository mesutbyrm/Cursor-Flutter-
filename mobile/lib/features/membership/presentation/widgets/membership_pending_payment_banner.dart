import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/payment_requests_notifier.dart';
import '../../../profile/presentation/widgets/pending_payment_banner.dart';

/// Bekleyen üyelik ödeme talebi — cüzdan, görevler ve profil hub.
///
/// Durum her zaman sunucudan gelir: banner ilk çizildiğinde ve uygulama öne
/// geldiğinde talepler sessizce yeniden çekilir (bayat "bekliyor" kalmaz).
class MembershipPendingPaymentBanner extends ConsumerStatefulWidget {
  const MembershipPendingPaymentBanner({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<MembershipPendingPaymentBanner> createState() =>
      _MembershipPendingPaymentBannerState();
}

class _MembershipPendingPaymentBannerState
    extends ConsumerState<MembershipPendingPaymentBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSilently());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshSilently();
  }

  void _refreshSilently() {
    if (!mounted) return;
    unawaited(
      ref.read(paymentRequestsNotifierProvider.notifier).refresh(silent: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref
            .watch(paymentRequestsNotifierProvider)
            .valueOrNull
            ?.where((r) => r.isMembershipCheckout && r.isPending)
            .toList() ??
        const [];
    if (pending.isEmpty) return const SizedBox.shrink();

    final first = pending.first;
    return Padding(
      padding: widget.padding,
      child: PendingPaymentBanner(
        request: first,
        kind: first.isJeton ? PendingPaymentKind.jeton : PendingPaymentKind.cfc,
        totalPending: pending.length,
      ),
    );
  }
}
