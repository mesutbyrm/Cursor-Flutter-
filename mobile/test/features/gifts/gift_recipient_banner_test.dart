import 'package:canlifal_social/features/gifts/presentation/widgets/gift_recipient_banner.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LiveGiftEvent _ev({String receiver = 'Ayşe', int qty = 1}) => LiveGiftEvent(
      id: 'g1',
      senderName: 'Mehmet',
      receiverName: receiver,
      giftId: 'rose',
      giftName: 'Gül',
      quantity: qty,
      coinCost: 10,
      timestamp: DateTime(2026, 1, 1),
    );

void main() {
  testWidgets('gönderen → alıcı ve hediye adı görünür', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: GiftRecipientBanner(event: _ev(qty: 3)))),
      ),
    );
    expect(find.text('Mehmet'), findsOneWidget);
    expect(find.text('Ayşe'), findsOneWidget);
    expect(find.text('Gül x3'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });

  testWidgets('alıcı yoksa (oda geneli) bant çizilmez', (tester) async {
    expect(GiftRecipientBanner.shouldShow(_ev(receiver: '  ')), isFalse);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GiftRecipientBanner(event: _ev(receiver: '')))),
    );
    expect(find.text('Mehmet'), findsNothing);
  });
}
