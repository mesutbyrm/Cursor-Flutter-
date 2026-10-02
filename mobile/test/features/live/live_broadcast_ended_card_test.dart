import 'package:canlifal_social/features/gifts/domain/session_gift_summary.dart';
import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_broadcast_ended_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget c) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: Center(child: c))),
    );

void main() {
  testWidgets('yayıncı: Canlı Yayın Özeti — 5 istatistik ve Kapat', (t) async {
    var closed = 0;
    await t.pumpWidget(
      _wrap(
        LiveBroadcastEndedCard(
          isHost: true,
          onClose: () => closed++,
          summary: const SessionGiftSummary(
            title: 'x',
            totalGrossJeton: 4000,
            myNetJeton: 2000,
            guestNetJeton: 0,
            senders: [],
            isHostOrOwner: true,
            duration: Duration(minutes: 42, seconds: 5),
            peakViewerCount: 318,
            likeCount: 1204,
            giftEventCount: 27,
          ),
        ),
      ),
    );
    expect(find.text('Canlı Yayın Özeti'), findsOneWidget);
    expect(find.text('Yayın süresi'), findsOneWidget);
    expect(find.text('42dk 5sn'), findsOneWidget);
    expect(find.text('318'), findsOneWidget);
    expect(find.text('1204'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    expect(find.text('2000'), findsOneWidget);
    await t.tap(find.text('Kapat'));
    expect(closed, 1);
  });

  testWidgets('izleyici: sade «Yayın bitti» kartı, istatistik yok', (t) async {
    await t.pumpWidget(
      _wrap(
        LiveBroadcastEndedCard(
          isHost: false,
          streamerName: 'Selin',
          onClose: () {},
        ),
      ),
    );
    expect(find.text('Yayın bitti'), findsOneWidget);
    expect(find.textContaining('Selin'), findsOneWidget);
    expect(find.text('Yayın süresi'), findsNothing);
  });
}
