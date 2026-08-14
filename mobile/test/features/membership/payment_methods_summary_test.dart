import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/profile/domain/entities/payment_method_entity.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/profile/presentation/widgets/payment_methods_summary_line.dart';

void main() {
  group('PaymentMethodsSummaryLine', () {
    testWidgets('API etiketlerini gösterir', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentMethodsProvider.overrideWith(
              (ref) async => const [
                PaymentMethodEntity(id: 'whatsapp', label: 'WhatsApp'),
                PaymentMethodEntity(id: 'papara', label: 'Papara'),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PaymentMethodsSummaryLine(prefix: 'Ödeme'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('WhatsApp'), findsOneWidget);
      expect(find.textContaining('Papara'), findsOneWidget);
    });

    test('labelsFrom checkoutMethods kullanır', () {
      final labels = PaymentMethodsSummaryLine.labelsFrom(const [
        PaymentMethodEntity(id: 'whatsapp', label: 'WhatsApp'),
        PaymentMethodEntity(id: 'crypto', label: 'Kripto'),
      ]);
      expect(labels, 'WhatsApp');
    });

    test('labelsFrom boş listede varsayılanlar', () {
      final labels = PaymentMethodsSummaryLine.labelsFrom(const [
        PaymentMethodEntity(id: 'crypto', label: 'Kripto', enabled: true),
      ]);
      expect(labels, contains('WhatsApp'));
    });

    testWidgets('showRecommended önerilen kanal ipucu', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentMethodsProvider.overrideWith(
              (ref) async => const [
                PaymentMethodEntity(
                  id: 'whatsapp',
                  label: 'WhatsApp',
                  recommended: true,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PaymentMethodsSummaryLine(prefix: 'Ödeme'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('önerilen:'), findsOneWidget);
    });

    testWidgets('showRecommended false ipucu göstermez', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentMethodsProvider.overrideWith(
              (ref) async => const [
                PaymentMethodEntity(
                  id: 'whatsapp',
                  label: 'WhatsApp',
                  recommended: true,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PaymentMethodsSummaryLine(
                prefix: 'Ödeme',
                showRecommended: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('önerilen:'), findsNothing);
    });
  });
}
