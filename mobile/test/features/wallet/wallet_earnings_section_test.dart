import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';
import 'package:canlifal_social/features/wallet/presentation/widgets/wallet_earnings_section.dart';

void main() {
  group('WalletEarningsSection', () {
    testWidgets('ücretsiz kullanıcı üyelik teaser', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WalletEarningsSection(
                balances: WalletBalances.empty,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kazanç Özeti'), findsOneWidget);
      expect(find.textContaining('Üyelik planları'), findsOneWidget);
    });
  });
}

class _StubMembershipController extends MembershipController {
  @override
  MembershipUiState build() => const MembershipUiState();
}
