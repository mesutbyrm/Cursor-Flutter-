import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_screen_state.dart';
import 'package:canlifal_social/features/profile/presentation/profile_hub/profile_hub_tabbed_sections.dart';
import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

const kTestUser = UserEntity(id: 'u1', username: 'tester');

class FakeWallet extends WalletBalancesNotifier {
  @override
  Future<WalletBalances> build() async =>
      const WalletBalances(jeton: 1250, cfc: 520);
}

class FakeAuth extends AuthController {
  FakeAuth(this.u);
  final UserEntity u;
  @override
  Future<UserEntity?> build() async => u;
}

void main() {
  testWidgets('profil bölümleri düğme; dokununca alttan sayfada açılır',
      (t) async {
    const st = ProfileScreenState(user: kTestUser, jeton: 1250, cfc: 520);
    t.view.physicalSize = const Size(390, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const SizedBox());
    await shotlessPump(t, st);
  });
}

Future<void> shotlessPump(WidgetTester t, ProfileScreenState st) async {
  await t.pumpWidget(ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => FakeAuth(kTestUser)),
      walletBalancesProvider.overrideWith(FakeWallet.new),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProfileHubTabbedSections(state: st, userId: 'u1'),
        ),
      ),
    ),
  ));
  await t.pump(const Duration(milliseconds: 600));
  for (var i = 0; i < 4; i++) {
    expect(find.byKey(Key('profile-section-$i')), findsOneWidget);
  }
  // Akordeon yok: içerik sayfada gömülü değil.
  expect(find.text('Profil Düzenle'), findsNothing);
  await t.tap(find.byKey(const Key('profile-section-3')));
  await t.pump(const Duration(milliseconds: 600));
  expect(find.text('Profil Düzenle'), findsOneWidget);
  expect(find.byTooltip('Kapat'), findsOneWidget);
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(minutes: 3));
  while (t.takeException() != null) {}
}
