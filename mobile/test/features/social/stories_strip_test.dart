import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/social/domain/entities/social_story_ring_entity.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_providers.dart';
import 'package:canlifal_social/features/social/presentation/providers/story_seen_provider.dart';
import 'package:canlifal_social/features/social/presentation/widgets/stories_strip.dart';
import 'package:canlifal_social/features/social/presentation/widgets/story_ring_tile.dart';

class _NoAuth extends AuthController {
  @override
  Future<UserEntity?> build() async => null;
}

SocialStoryRingEntity ring(String id) => SocialStoryRingEntity(
  user: UserEntity(id: id, username: id, displayName: 'K-$id'),
  stories: [SocialStoryItemEntity(id: 's-$id', mediaUrl: '')],
);

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      StorySeenNotifier.prefsKey: ['s-a'],
    }),
  );

  Widget host(Future<List<SocialStoryRingEntity>> Function() load) =>
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_NoAuth.new),
          socialStoryRingsProvider.overrideWith((ref) => load()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: StoriesStrip()),
        ),
      );

  testWidgets('yüklenirken iskelet gösterir', (tester) async {
    final pending = Completer<List<SocialStoryRingEntity>>();
    await tester.pumpWidget(host(() => pending.future));
    await tester.pump();
    expect(find.byType(StoryRingSkeletonRow), findsOneWidget);
    pending.complete(const []);
    await tester.pump();
    // Parıltı animasyonunun zamanlayıcılarını boşalt.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('izlenmemiş halkalar önce, izlenen soluk durumda', (
    tester,
  ) async {
    await tester.pumpWidget(host(() async => [ring('a'), ring('b')]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final tiles = tester
        .widgetList<StoryRingTile>(find.byType(StoryRingTile))
        .toList();
    expect(tiles.first.label, 'Hikâyen');
    expect(tiles.first.state, StoryRingState.none);
    expect(tiles[1].label, 'K-b');
    expect(tiles[1].state, StoryRingState.unseen);
    expect(tiles[2].label, 'K-a');
    expect(tiles[2].state, StoryRingState.seen);
  });
}
