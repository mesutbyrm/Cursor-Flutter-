import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/profile/domain/repositories/profile_repository.dart';
import 'package:canlifal_social/features/profile/presentation/pages/profile_follow_list_page.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_theme.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/widgets/profile_action_tile.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/profile/presentation/widgets/profile_follow_button.dart';

class _FakeRepo implements ProfileRepository {
  var follows = 0;
  var unfollows = 0;
  Completer<void>? gate;
  Object? failWith;

  Future<void> _run() async {
    final g = gate;
    if (g != null) await g.future;
    if (failWith != null) throw failWith!;
  }

  @override
  Future<void> follow(String id) {
    follows++;
    return _run();
  }

  @override
  Future<void> unfollow(String id) {
    unfollows++;
    return _run();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('ProfileActionTile (hızlı menü)', () {
    for (final theme in {
      'koyu': AppTheme.dark,
      'açık': AppTheme.light,
    }.entries) {
      testWidgets(
        '${theme.key}: sıkı kutucuk en uzun etiketle %130 yazıda taşmaz',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme.value(),
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
                child: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 78,
                      height: ProfileActionTile.compactHeight,
                      child: ProfileActionTile(
                        compact: true,
                        icon: Icons.card_giftcard_rounded,
                        label: 'Hediye Geçmişim',
                        badge: 3,
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('açık temada etiket okunur (koyu metin, açık zemin)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ProfileActionTile(
              icon: Icons.wallet,
              label: 'Cüzdanım',
              onTap: () {},
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Cüzdanım'));
      expect(
        _contrast(text.style!.color!, AppTheme.light().colorScheme.surface),
        greaterThan(7),
      );
    });
  });

  group('ProfilePremiumTheme temaya duyarlı renkler', () {
    for (final theme in {
      'koyu': AppTheme.dark,
      'açık': AppTheme.light,
    }.entries) {
      testWidgets('${theme.key}: kart metni kart yüzeyinde okunur', (
        tester,
      ) async {
        late Color text;
        late Color surface;
        late Color bg;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.value(),
            home: Builder(
              builder: (context) {
                text = ProfilePremiumTheme.textOf(context);
                surface = ProfilePremiumTheme.surfaceOf(context);
                bg = Theme.of(context).scaffoldBackgroundColor;
                return const SizedBox();
              },
            ),
          ),
        );
        final flat = Color.alphaBlend(surface, bg);
        expect(_contrast(text, flat), greaterThan(7));
      });
    }
  });

  group('ProfileFollowButton', () {
    late _FakeRepo repo;
    setUp(() => repo = _FakeRepo());

    Widget host({bool following = false}) => ProviderScope(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: ProfileFollowButton(userId: 'u1', isFollowing: following),
            ),
          ),
        ),
      ),
    );

    testWidgets('dokununca anında "Takibi bırak" olur ve tek istek gider', (
      tester,
    ) async {
      repo.gate = Completer<void>();
      await tester.pumpWidget(host());
      await tester.tap(find.text('Takip et'));
      await tester.pump();
      expect(find.text('Takibi bırak'), findsOneWidget);

      // İstek sürerken ikinci dokunuş yok sayılır.
      await tester.tap(find.text('Takibi bırak'), warnIfMissed: false);
      await tester.pump();
      expect(repo.follows, 1);
      expect(repo.unfollows, 0);

      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Takibi bırak'), findsOneWidget);
    });

    testWidgets('istek başarısız olursa eski duruma döner ve bildirir', (
      tester,
    ) async {
      repo.failWith = Exception('ağ yok');
      await tester.pumpWidget(host());
      await tester.tap(find.text('Takip et'));
      await tester.pumpAndSettle();
      expect(find.text('Takip et'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('takip edilen kullanıcıda takibi bırakır', (tester) async {
      await tester.pumpWidget(host(following: true));
      await tester.tap(find.text('Takibi bırak'));
      await tester.pumpAndSettle();
      expect(repo.unfollows, 1);
      expect(find.text('Takip et'), findsOneWidget);
    });
  });

  testWidgets('takipçi listesinde kişiye dokununca /user/<id> açılır', (
    tester,
  ) async {
    String? opened;
    final router = GoRouter(
      initialLocation: '/list',
      routes: [
        GoRoute(
          path: '/list',
          builder: (_, _) => const ProfileFollowListPage(
            userId: 'me',
            tab: ProfileFollowTab.followers,
          ),
        ),
        GoRoute(
          path: '/user/:id',
          builder: (_, state) {
            opened = state.pathParameters['id'];
            return const Scaffold(body: Text('profil'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userFollowersProvider.overrideWith(
            (ref, id) async => const [
              UserEntity(id: 'u42', username: 'mehmet', displayName: 'Mehmet'),
            ],
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Mehmet'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(opened, 'u42');
    expect(find.text('profil'), findsOneWidget);
  });
}
