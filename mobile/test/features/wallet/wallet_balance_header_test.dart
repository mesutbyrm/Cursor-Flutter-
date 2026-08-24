import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/wallet/presentation/widgets/wallet_balance_header.dart';

void main() {
  group('WalletBalanceHeader', () {
    testWidgets('süresi dolmuş üyelik quick link yenile', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WalletBalanceHeader(
                jeton: 100,
                cfc: 50,
                membership: 'gold',
                daysRemaining: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yenile'), findsOneWidget);
    });

    testWidgets('aktif gold quick link tier etiketi', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WalletBalanceHeader(
                jeton: 100,
                cfc: 50,
                membership: 'gold',
                daysRemaining: 4,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gold'), findsOneWidget);
    });
  });
}

class _StubMembershipController extends MembershipController {
  @override
  MembershipUiState build() => const MembershipUiState();
}
