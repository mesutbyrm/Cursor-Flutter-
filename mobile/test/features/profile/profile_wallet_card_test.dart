import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_screen_state.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/widgets/profile_wallet_card.dart';

void main() {
  const user = UserEntity(id: 'u1', username: 'tester');

  group('ProfileWalletCard', () {
    testWidgets('ücretsiz kullanıcı standart premium stat ve planlar karo', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProfileWalletCard(
                state: const ProfileScreenState(
                  user: user,
                  membership: 'basic',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Standart'), findsOneWidget);
      expect(find.text('Planlar'), findsOneWidget);
    });

    testWidgets('süresi dolmuş gold yenile karo', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProfileWalletCard(
                state: const ProfileScreenState(
                  user: user,
                  membership: 'gold',
                  membershipDays: 0,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gold'), findsNWidgets(2));
      expect(find.text('Yenile'), findsOneWidget);
    });
  });
}

class _StubMembershipController extends MembershipController {
  @override
  MembershipUiState build() => const MembershipUiState();
}
