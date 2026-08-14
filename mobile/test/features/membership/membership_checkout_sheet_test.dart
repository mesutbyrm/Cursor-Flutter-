import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/domain/membership_model.dart';
import 'package:canlifal_social/features/membership/presentation/widgets/membership_checkout_sheet.dart';
import 'package:canlifal_social/features/profile/domain/entities/payment_method_entity.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/profile/presentation/widgets/payment_methods_summary_line.dart';

void main() {
  const tier = MembershipTierModel(
    id: MembershipTierId.gold,
    title: 'Gold',
    subtitle: 'Test',
    monthlyTokens: 1500,
    monthlyPriceTry: 1000,
    accent: Color(0xFFFFD54F),
    badgeIcon: Icons.star,
    glow: Color(0xFFFFC107),
    durationDays: 30,
  );

  group('showMembershipCheckoutSheet', () {
    testWidgets('ödeme seçenekleri ve özet satırı gösterilir', (tester) async {
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
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showMembershipCheckoutSheet(
                          context,
                          tier: tier,
                          priceJeton: 2000,
                          priceCfc: 500,
                          cfcBalance: 100,
                          externalMethodsLabel:
                              PaymentMethodsSummaryLine.externalCheckoutFallback,
                        );
                      },
                      child: const Text('Aç'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(find.text('Gold üyeliği · ödeme'), findsOneWidget);
      expect(find.textContaining('WhatsApp'), findsWidgets);
      expect(find.text('CFC ile öde'), findsOneWidget);
      expect(find.textContaining('Bakiye yetersiz'), findsOneWidget);
    });
  });
}
