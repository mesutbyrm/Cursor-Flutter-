import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/profile/presentation/profile_hub/profile_hub_vip_banner.dart';

void main() {
  group('ProfileHubVipBanner', () {
    testWidgets('ücretsiz kullanıcı teaser alt başlık', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProfileHubVipBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Premium Üyelik'), findsOneWidget);
      expect(find.textContaining('öne çıkan'), findsOneWidget);
    });
  });
}

class _StubMembershipController extends MembershipController {
  @override
  MembershipUiState build() => const MembershipUiState();
}
