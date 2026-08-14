import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payment_method_entity.dart';
import '../providers/profile_providers.dart';

/// `GET /api/payments/methods` — tek satır özet (üyelik, cüzdan, footer).
class PaymentMethodsSummaryLine extends ConsumerWidget {
  const PaymentMethodsSummaryLine({
    super.key,
    this.prefix = 'Ödeme',
    this.textAlign = TextAlign.center,
    this.fontSize = 11,
    this.textColor,
    this.showRecommended = true,
  });

  final String prefix;
  final TextAlign textAlign;
  final double fontSize;
  final Color? textColor;
  final bool showRecommended;

  static String fallbackLabels() {
    return PaymentMethodEntity.defaults.map((m) => m.label).join(' · ');
  }

  static String labelsFrom(List<PaymentMethodEntity> methods) {
    final enabled = methods
        .where(
          (m) => m.enabled && PaymentMethodEntity.isKnownCheckoutMethod(m.id),
        )
        .toList();
    final list = enabled.isNotEmpty ? enabled : PaymentMethodEntity.defaults;
    return list.map((m) => m.label).join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);
    final color = textColor ?? Colors.white.withValues(alpha: 0.45);
    final style = TextStyle(fontSize: fontSize, color: color, height: 1.35);

    return methodsAsync.when(
      loading: () => Text(
        _line(prefix, 'yükleniyor…'),
        textAlign: textAlign,
        style: style,
      ),
      error: (_, _) => Text(
        _line(prefix, fallbackLabels()),
        textAlign: textAlign,
        style: style,
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
        final recommended = showRecommended
            ? list.where((m) => m.recommended).toList()
            : const <PaymentMethodEntity>[];
        final hint = recommended.isNotEmpty
            ? ' · önerilen: ${recommended.first.label}'
            : '';

        return Text(
          _line(prefix, '$labels$hint'),
          textAlign: textAlign,
          style: style,
        );
      },
    );
  }

  static String _line(String prefix, String body) {
    final p = prefix.trim();
    return p.isEmpty ? body : '$p: $body';
  }
}
