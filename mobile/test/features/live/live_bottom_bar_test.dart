import 'package:canlifal_social/features/live/presentation/widgets/premium_2026/live/live_broadcast_bottom_bar_v2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _bar({required bool host, required bool multi}) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: LiveBroadcastBottomBarV2(
            chatController: TextEditingController(),
            onSend: () {},
            isHost: host,
            onGift: () {},
            onMore: () {},
            onGuest: () {},
            onMulti: host ? () {} : null,
            onShare: () {},
            onSettings: host ? () {} : null,
            multiLayoutActive: multi,
          ),
        ),
      ),
    );

void main() {
  testWidgets('tekli yayın (yayıncı): Misafir · Çoklu · Hediye · Paylaş', (t) async {
    await t.pumpWidget(_bar(host: true, multi: false));
    for (final l in ['Misafir', 'Çoklu', 'Hediye', 'Paylaş', 'Daha fazla']) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
    expect(find.text('Ayarlar'), findsNothing);
    expect(find.text('Yorum yaz...'), findsOneWidget);
  });

  testWidgets('2x2 çoklu (yayıncı): Çoklu/Paylaş yerine Ayarlar', (t) async {
    await t.pumpWidget(_bar(host: true, multi: true));
    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Çoklu'), findsNothing);
    expect(find.text('Paylaş'), findsNothing);
    expect(find.text('Hediye'), findsOneWidget);
  });

  testWidgets('izleyici: Çoklu yok; hediye listesi sahte dropdown değil', (t) async {
    await t.pumpWidget(_bar(host: false, multi: false));
    expect(find.text('Çoklu'), findsNothing);
    await t.tap(find.text('Hediye'));
    await t.pump();
    expect(find.textContaining('Elmas'), findsNothing);
  });
}
