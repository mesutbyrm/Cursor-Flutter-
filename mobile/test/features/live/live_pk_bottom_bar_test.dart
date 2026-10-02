import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_pk_immersive_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PK alt çubuk: Yorum yaz…, Hediye, Paylaş; Gönder yalnız yazarken', (
    t,
  ) async {
    final ctrl = TextEditingController();
    var gift = 0, share = 0, sent = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: LivePkChatInputBar(
              controller: ctrl,
              onSend: () => sent++,
              onGift: () => gift++,
              onShare: () => share++,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Yorum yaz...'), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsNothing);

    await t.tap(find.text('Hediye'));
    await t.tap(find.text('Paylaş'));
    expect((gift, share), (1, 1));

    await t.enterText(find.byType(TextField), 'selam');
    await t.pump();
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    await t.tap(find.byIcon(Icons.send_rounded));
    expect(sent, 1);
  });

  testWidgets('yayıncı kontrolleri: etiketler ve PK bitir tetiklenir', (t) async {
    var ended = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LivePkImmersiveControls(
            items: [
              LivePkControlItem(icon: Icons.mic_rounded, label: 'Mikrofon', onTap: () {}),
              LivePkControlItem(
                icon: Icons.flag_rounded,
                label: 'PK bitir',
                danger: true,
                onTap: () => ended++,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Mikrofon'), findsOneWidget);
    await t.tap(find.text('PK bitir'));
    expect(ended, 1);
  });
}
