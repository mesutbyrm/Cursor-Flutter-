import 'package:canlifal_social/features/live/domain/entities/live_broadcast_session.dart';
import 'package:canlifal_social/features/live/presentation/widgets/premium_2026/live/live_premium_chat_feed.dart';
import 'package:canlifal_social/features/live/presentation/widgets/premium_2026/live/live_premium_top_bar.dart';
import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_room_chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    );

void main() {
  testWidgets('üst bar: beğeni etiketi, Takip et, K formatlı izleyici, çipler', (
    t,
  ) async {
    await t.pumpWidget(
      _wrap(
        LivePremiumTopBar(
          session: const LiveBroadcastSession(
            title: 't',
            category: 'c',
            isHost: false,
            streamerName: 'Canlifal',
            viewerCount: 12400,
          ),
          elapsedBadge: const SizedBox.shrink(),
          following: false,
          followLoading: false,
          onFollow: () {},
          onClose: () {},
          likeLabel: '1.2M beğeni',
          onPopularTap: () {},
          onDiscoverTap: () {},
        ),
      ),
    );
    expect(find.text('Canlifal'), findsOneWidget);
    expect(find.text('1.2M beğeni'), findsOneWidget);
    expect(find.text('Takip et'), findsOneWidget);
    expect(find.text('12.4K'), findsOneWidget);
    expect(find.text('Saatlik Sıralama'), findsOneWidget);
    expect(find.text('Popüler'), findsOneWidget);
    expect(find.text('Keşfet >'), findsOneWidget);
  });

  testWidgets('sohbet: avatar baş harfi, ad üstte, mesaj altta', (t) async {
    await t.pumpWidget(
      _wrap(
        const LivePremiumChatFeed(
          messages: [LiveRoomChatMessage(user: 'Mert', text: 'Harika yayın')],
        ),
      ),
    );
    expect(find.text('M'), findsOneWidget);
    expect(find.text('Mert'), findsOneWidget);
    expect(find.text('Harika yayın'), findsOneWidget);
  });
}
