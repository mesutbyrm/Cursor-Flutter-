import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_message.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/girlive_rules_notice_provider.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_chat_message_filters.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/premium_2026/voice_web_chat_overlay.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ChatRoomMessage _msg(String id, String text, DateTime at, {String who = 'Ali'}) =>
    ChatRoomMessage(
      id: id,
      content: text,
      createdAt: at,
      user: ChatRoomUserRef(id: 'u-$who', name: who),
    );

void main() {
  test('kural satırı 15 sn sonra kendiliğinden kalkar ve odaya bağlıdır', () {
    fakeAsync((fa) {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(girLiveRulesNoticeProvider.notifier).show('Kurallar', roomKey: 'r1');
      final n = c.read(girLiveRulesNoticeProvider)!;
      expect(n.belongsTo('r1'), isTrue);
      expect(n.belongsTo('r2'), isFalse);
      fa.elapse(const Duration(seconds: 14));
      expect(c.read(girLiveRulesNoticeProvider), isNotNull);
      fa.elapse(const Duration(seconds: 2));
      expect(c.read(girLiveRulesNoticeProvider), isNull);
    });
  });

  test('geçmişten gelen eski selam hemen süresi dolmuş sayılır', () {
    final now = DateTime(2026, 1, 1, 12);
    final old = now.subtract(const Duration(minutes: 5));
    expect(
      now.difference(VoiceChatMessageFilters.welcomeClockStart(old, now)) >=
          VoiceChatMessageFilters.botWelcomeVisible,
      isTrue,
    );
    // Sunucu saati ileride → şimdiden say.
    final future = now.add(const Duration(minutes: 1));
    expect(VoiceChatMessageFilters.welcomeClockStart(future, now), now);
    expect(
      VoiceChatMessageFilters.isBotWelcome(
        _msg('w', '👋 Hoşgeldin @ali', now, who: 'GirLive Bot'),
      ),
      isTrue,
    );
  });

  testWidgets('kural satırı sohbette görünür; eski bot selamı görünmez', (t) async {
    final now = DateTime.now();
    await t.pumpWidget(ProviderScope(child: MaterialApp(
      home: Scaffold(
        body: VoiceWebChatOverlay(
          embedded: true,
          botNotice: 'Küfür ve spam yasaktır.',
          messages: [
            _msg('w1', '👋 Hoş geldin @veli!',
                now.subtract(const Duration(minutes: 3)), who: 'GirLive Bot'),
            _msg('m1', 'selam', now),
          ],
        ),
      ),
    )));
    await t.pump();
    expect(find.textContaining('Küfür ve spam yasaktır.'), findsOneWidget);
    expect(find.textContaining('Hoş geldin @veli', findRichText: true), findsNothing);
    expect(find.textContaining('selam', findRichText: true), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
