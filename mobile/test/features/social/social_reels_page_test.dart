import 'package:canlifal_social/core/network/cookie_jar_provider.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/live/domain/entities/live_stream_entity.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/live/presentation/providers/live_streams_list_notifier.dart';
import 'package:canlifal_social/features/live/presentation/providers/voice_rooms_list_notifier.dart';
import 'package:canlifal_social/features/shorts/domain/entities/short_explore_entity.dart';
import 'package:canlifal_social/features/shorts/presentation/providers/shorts_explore_providers.dart';
import 'package:canlifal_social/features/social/presentation/models/social_feed_item.dart';
import 'package:canlifal_social/features/social/presentation/pages/social_page.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_reels_provider.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GirLive Sosyal: Canlı · Keşfet · Video · Takipte, Keşfet ızgarası',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookieJarProvider.overrideWithValue(PersistCookieJar()),
          authControllerProvider.overrideWith(
            () => _FakeAuth(const UserEntity(id: 'u1', username: 'admin', displayName: 'Admin')),
          ),
          socialReelsProvider.overrideWith(_StubReels.new),
          liveStreamsListNotifierProvider.overrideWith(_StubLives.new),
          voiceRoomsListNotifierProvider.overrideWith(_StubRooms.new),
          shortsExploreProvider.overrideWith(_StubExplore.new),
        ],
        child: const MaterialApp(home: SocialPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    for (final t in ['Canlı', 'Keşfet', 'Video', 'Takipte']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    // Keşfet ızgarasında yazı paylaşımı kutusu.
    expect(find.text('Merhaba GirLive'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('her 5 içerikten sonra reklam sayfası', () {
    final posts = [
      for (var i = 0; i < 12; i++)
        PostFeedItem(PostEntity(
          id: 'p$i',
          author: const UserEntity(id: 'u', username: 'u'),
          caption: 'x',
        )),
    ];
    final out = withAdSlots(posts);
    expect(out.length, 14);
    expect(out[5], isA<AdFeedItem>());
    expect(out[11], isA<AdFeedItem>());
  });
}

class _FakeAuth extends AuthController {
  _FakeAuth(this._user);
  final UserEntity _user;
  @override
  Future<UserEntity?> build() async => _user;
}

class _StubReels extends SocialReelsNotifier {
  @override
  Future<List<PostEntity>> build(String feed) async => [
        const PostEntity(
          id: 'p1',
          author: UserEntity(id: 'u2', username: 'ayse', displayName: 'Ayşe'),
          caption: 'Merhaba GirLive',
          likesCount: 3,
        ),
      ];
}

class _StubLives extends LiveStreamsListNotifier {
  @override
  Future<List<LiveStreamEntity>> build() async => const [];
}

class _StubRooms extends VoiceRoomsListNotifier {
  @override
  Future<List<VoiceRoomEntity>> build() async => const [];
}

class _StubExplore extends ShortsExploreNotifier {
  @override
  Future<ShortExplorePage> build() async => const ShortExplorePage(videos: []);
}
