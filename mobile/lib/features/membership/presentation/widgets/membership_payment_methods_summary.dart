import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/entities/payment_method_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Üyelik sayfası — `GET /api/payments/methods` canlı özet.
class MembershipPaymentMethodsSummary extends ConsumerWidget {
  const MembershipPaymentMethodsSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return methodsAsync.when(
      loading: () => Text(
        'Ödeme yöntemleri yükleniyor…',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.45),
          height: 1.35,
        ),
      ),
      error: (_, _) => Text(
        'Ödeme: WhatsApp · Papara · Havale',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.45),
          height: 1.35,
        ),
      ),
      data: (methods) {
        final enabled = methods
            .where(
              (m) =>
                  m.enabled && PaymentMethodEntity.isKnownCheckoutMethod(m.id),
            )
            .toList();
        final list = enabled.isNotEmpty ? enabled : PaymentMethodEntity.defaults;
        final labels = list.map((m) => m.label).join(' · ');
        final recommended = list.where((m) => m.recommended).toList();
        final hint = recommended.isNotEmpty
            ? ' · önerilen: ${recommended.first.label}'
            : '';

        return Text(
          'Ödeme: $labels$hint',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.45),
            height: 1.35,
          ),
        );
      },
    );
  }
}
