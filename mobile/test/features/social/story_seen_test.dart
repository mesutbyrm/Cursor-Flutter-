import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/social/domain/entities/social_story_ring_entity.dart';
import 'package:canlifal_social/features/social/presentation/pages/story_viewer_page.dart';
import 'package:canlifal_social/features/social/presentation/providers/story_seen_provider.dart';

SocialStoryRingEntity ring(String user, List<String> ids) =>
    SocialStoryRingEntity(
      user: UserEntity(id: user, username: user),
      stories: [
        for (final id in ids) SocialStoryItemEntity(id: id, mediaUrl: 'x'),
      ],
    );

void main() {
  group('isStoryRingSeen', () {
    test('yalnızca tüm hikâyeler izlendiyse görüldü sayılır', () {
      final r = ring('a', ['1', '2']);
      expect(isStoryRingSeen(r, {'1'}), isFalse);
      expect(isStoryRingSeen(r, {'1', '2'}), isTrue);
    });

    test('hikâyesi olmayan halka izlenmemiş sayılır', () {
      expect(isStoryRingSeen(ring('a', []), {'1'}), isFalse);
    });
  });

  test('izlenmemiş halkalar öne alınır, kendi aralarında sıra korunur', () {
    final a = ring('a', ['1']);
    final b = ring('b', ['2']);
    final c = ring('c', ['3']);
    final d = ring('d', ['4']);
    final sorted = sortRingsUnseenFirst([a, b, c, d], {'1', '3'});
    expect(sorted.map((r) => r.user.id), ['b', 'd', 'a', 'c']);
  });

  group('StorySeenNotifier', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('işaretlenen hikâye kalıcı olarak saklanır', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(storySeenProvider.notifier).markSeen('s1');
      expect(container.read(storySeenProvider), {'s1'});
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(StorySeenNotifier.prefsKey), ['s1']);
    });

    test('açılışta önceki kayıtlar yüklenir', () async {
      SharedPreferences.setMockInitialValues({
        StorySeenNotifier.prefsKey: ['old'],
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(storySeenProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(container.read(storySeenProvider), contains('old'));
    });

    test('kayıt sayısı sınırlıdır; en eskiler düşer', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(storySeenProvider.notifier);
      for (var i = 0; i < StorySeenNotifier.maxEntries + 5; i++) {
        n.markSeen('s$i');
      }
      final seen = container.read(storySeenProvider);
      expect(seen.length, StorySeenNotifier.maxEntries);
      expect(seen.contains('s0'), isFalse);
      expect(seen.contains('s${StorySeenNotifier.maxEntries + 4}'), isTrue);
    });
  });

  test('storyTimeAgo kısa göreli zaman üretir', () {
    final now = DateTime(2026, 9, 26, 12);
    expect(
      storyTimeAgo(now.subtract(const Duration(seconds: 20)), now),
      'az önce',
    );
    expect(storyTimeAgo(now.subtract(const Duration(minutes: 5)), now), '5 dk');
    expect(storyTimeAgo(now.subtract(const Duration(hours: 3)), now), '3 sa');
    expect(storyTimeAgo(now.subtract(const Duration(days: 2)), now), '2 gün');
  });
}
