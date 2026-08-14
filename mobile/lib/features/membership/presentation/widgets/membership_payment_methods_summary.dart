import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/widgets/payment_methods_summary_line.dart';

/// Üyelik sayfası — canlı ödeme kanalı özeti.
class MembershipPaymentMethodsSummary extends ConsumerWidget {
  const MembershipPaymentMethodsSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PaymentMethodsSummaryLine(
      prefix: 'Ödeme',
      textAlign: TextAlign.center,
    );
  }
}
