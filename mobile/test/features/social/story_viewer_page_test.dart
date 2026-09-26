import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/social/domain/entities/social_story_ring_entity.dart';
import 'package:canlifal_social/features/social/presentation/pages/story_viewer_page.dart';
import 'package:canlifal_social/features/social/presentation/providers/story_seen_provider.dart';

SocialStoryRingEntity ring(String user, int count) => SocialStoryRingEntity(
  user: UserEntity(id: user, username: user, displayName: 'Kişi $user'),
  stories: [
    for (var i = 0; i < count; i++)
      SocialStoryItemEntity(
        id: '$user-$i',
        // Geçersiz adres anında "yüklenemedi" sayılır; süreli ilerleme işler.
        mediaUrl: '',
        durationMs: 1000,
      ),
  ],
);

class _NoAuth extends AuthController {
  @override
  Future<UserEntity?> build() async => null;
}

/// pumpAndSettle kullanılmaz: açıkken ilerleme animasyonu sürekli kare ister.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// Zamanı kare kare ilerletir (ticker süreyi ilk kareden sayar).
Future<void> advance(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

/// Sayfa kapandıktan sonra çıkış geçişinin bitmesini bekler.
Future<void> settleClosed(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_NoAuth.new)],
    );
  });
  tearDown(() => container.dispose());

  Future<void> open(
    WidgetTester tester,
    SocialStoryRingEntity first, {
    List<SocialStoryRingEntity> rings = const [],
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/story'),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/story',
          builder: (_, _) => StoryViewerPage(ring: first, rings: rings),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('aç'));
    await settle(tester);
  }

  String indicator(WidgetTester tester) {
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Hikâye \d+ / \d+$')),
    );
    return node.label;
  }

  testWidgets('tek hikâyede de ilerleme göstergesi görünür', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, ring('a', 1));
    expect(indicator(tester), 'Hikâye 1 / 1');
    handle.dispose();
  });

  testWidgets('sağa dokununca sonraki hikâyeye geçer, sonda kapanır', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, ring('a', 2));
    expect(indicator(tester), 'Hikâye 1 / 2');

    await tester.tapAt(const Offset(700, 400));
    await settle(tester);
    expect(indicator(tester), 'Hikâye 2 / 2');

    await tester.tapAt(const Offset(700, 400));
    await settle(tester);
    await settleClosed(tester);
    expect(find.byType(StoryViewerPage), findsNothing);
    expect(find.text('aç'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('süre dolunca kendiliğinden ilerler', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, ring('a', 2));
    await advance(tester, const Duration(milliseconds: 1100));
    expect(indicator(tester), 'Hikâye 2 / 2');
    handle.dispose();
  });

  testWidgets('bir kişinin hikâyeleri bitince sıradaki kişiye geçer', (
    tester,
  ) async {
    final a = ring('a', 1);
    final b = ring('b', 1);
    await open(tester, a, rings: [a, b]);
    expect(find.text('Kişi a'), findsOneWidget);

    await tester.tapAt(const Offset(700, 400));
    await settle(tester);
    expect(find.text('Kişi b'), findsOneWidget);

    // İlk hikâyede sola dokunmak önceki kişiye döner.
    await tester.tapAt(const Offset(50, 400));
    await settle(tester);
    expect(find.text('Kişi a'), findsOneWidget);
  });

  testWidgets('basılı tutmak duraklatır; bırakınca kaldığı yerden sürer', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, ring('a', 2));
    await advance(tester, const Duration(milliseconds: 600));

    final gesture = await tester.startGesture(const Offset(700, 400));
    await advance(tester, const Duration(seconds: 3)); // basılı: duraklatılmış
    expect(indicator(tester), 'Hikâye 1 / 2');
    await gesture.up();

    // Sıfırlansaydı 1 sn daha gerekirdi; kalan ~400 ms yetmeli.
    await advance(tester, const Duration(milliseconds: 550));
    expect(indicator(tester), 'Hikâye 2 / 2');
    handle.dispose();
  });

  testWidgets('aşağı kaydırınca kapanır', (tester) async {
    await open(tester, ring('a', 2));
    await tester.fling(
      find.byType(StoryViewerPage),
      const Offset(0, 400),
      1500,
    );
    await settleClosed(tester);
    expect(find.byType(StoryViewerPage), findsNothing);
  });

  testWidgets('görüntülenen hikâye izlendi olarak kaydedilir', (tester) async {
    await open(tester, ring('a', 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(storySeenProvider), contains('a-0'));
  });
}
