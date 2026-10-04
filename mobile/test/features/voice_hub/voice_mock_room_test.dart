import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_mock/voice_mock_footer.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_mock/voice_mock_header.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_mock/voice_mock_seat_stage.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_mock/voice_mock_side_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

VoiceRoomEntity _room(int seats) =>
    VoiceRoomEntity(id: 'r1', slug: 's', nameTr: 'Oda', seatCount: seats);

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Stack(children: [child])),
    );

void main() {
  test('voiceMockCompactCount: 1.6M / 1.2K / 950', () {
    expect(voiceMockCompactCount(1600000), '1.6M');
    expect(voiceMockCompactCount(1200), '1.2K');
    expect(voiceMockCompactCount(12300), '12K');
    expect(voiceMockCompactCount(950), '950');
  });

  test('misafir koltukları: seatCount 8 → 2..8', () {
    final n = voiceMockGuestSeatNumbers(
      room: _room(8),
      seatSlots: const [],
      presence: const [],
    );
    expect(n, [2, 3, 4, 5, 6, 7, 8]);
  });

  test('seatCount > 10: başta 8 koltuk görünür; admin koltuğu yalnız doluysa eklenir',
      () {
    final empty = voiceMockGuestSeatNumbers(
      room: _room(12),
      seatSlots: const [],
      presence: const [],
    );
    expect(empty, [2, 3, 4, 5, 6, 7, 8]);
    final withAdmin = voiceMockGuestSeatNumbers(
      room: _room(12),
      seatSlots: const [],
      presence: const [
        ChatRoomPresence(id: 'a', name: 'Admin', seatIndex: 11),
      ],
    );
    expect(withAdmin.last, 11);
  });

  test('görünen koltuklar dolunca bir koltuk daha açılır (hepsi değil)', () {
    final full = [
      for (var i = 2; i <= 8; i++)
        ChatRoomPresence(id: 'u$i', name: 'U$i', seatIndex: i),
    ];
    final n = voiceMockGuestSeatNumbers(
      room: _room(12),
      seatSlots: const [],
      presence: full,
    );
    expect(n, [2, 3, 4, 5, 6, 7, 8, 9]);
  });

  testWidgets('koltuk: boş «Koltuk Aç», kilitli «Kilitli», sahip 👑 + ad', (t) async {
    Widget seat({int i = 5, bool host = false, bool locked = false, ChatRoomPresence? u}) =>
        VoiceMockSeat(
          seatIndex: i, isHost: host, user: u, locked: locked, micOpen: true,
          speaking: false, isRoomDj: false, giftCoins: 0,
        );
    await t.pumpWidget(_host(Row(children: [seat(), seat(i: 6, locked: true)])));
    expect(find.text('Koltuk Aç'), findsOneWidget);
    expect(find.text('Kilitli'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await t.pumpWidget(
      _host(seat(i: 1, host: true, u: const ChatRoomPresence(id: 'o', name: 'Admin', seatIndex: 1))),
    );
    // Oda sahibi kanatsız: yalnızca 👑 + ad (eski «Oda Sahibi» etiketi kalktı).
    expect(find.text('👑'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Oda Sahibi'), findsNothing);
  });

  testWidgets('dolu koltuk hediye değerini (12.3K) gösterir', (t) async {
    await t.pumpWidget(
      _host(
        VoiceMockSeat(
          seatIndex: 2,
          isHost: false,
          user: const ChatRoomPresence(id: 'u', name: 'Aslı', seatIndex: 2),
          locked: false, micOpen: true, speaking: false, isRoomDj: false,
          giftCoins: 12300,
        ),
      ),
    );
    expect(find.text('Aslı'), findsOneWidget);
    expect(find.text('12.3K'), findsOneWidget);
  });

  testWidgets('sağ düğmeler: Müzik · PK · İstek · Daha Fazla (Hediye dock\'ta)', (t) async {
    var taps = <String>[];
    await t.pumpWidget(
      _host(
        VoiceMockSideRail(
          onMusic: () => taps.add('music'),
          onPk: () => taps.add('pk'),
          onRequest: () => taps.add('req'),
          onMore: () => taps.add('more'),
        ),
      ),
    );
    for (final l in ['Müzik', 'PK', 'İstek', 'Daha Fazla']) {
      expect(find.text(l), findsWidgets, reason: l);
    }
    expect(find.text('Hediye'), findsNothing);
    await t.tap(find.text('İstek'));
    await t.tap(find.text('Daha Fazla'));
    expect(taps, ['req', 'more']);
  });

  testWidgets('alt dock: Ses · Mikrofon · Konuş · Hediye · Oda Modu', (t) async {
    var gift = 0;
    var mode = 0;
    var mic = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: VoiceMockFooterView(
              presence: const [],
              toast: const SizedBox.shrink(),
              headphonesOn: true,
              sendEnabled: true,
              hideInput: false,
              userId: 'u',
              controller: TextEditingController(),
              focusNode: FocusNode(),
              micOn: false,
              micEnabled: true,
              onSend: () {},
              onToggleAudioOutput: () {},
              onMicToggle: () => mic++,
              onGift: () => gift++,
              onEmojiTap: () {},
              onChanged: (_) {},
              onRoomMode: () => mode++,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Ses açık'), findsOneWidget); // hoparlör açık
    expect(find.text('Kapalı'), findsOneWidget); // mikrofon kapalı
    expect(find.text('Konuş'), findsOneWidget);
    expect(find.text('Hediye'), findsOneWidget);
    expect(find.text('Efektler'), findsNothing);
    expect(find.text('Oda Modu'), findsOneWidget);
    expect(find.text('Mesaj yaz... (istek)'), findsOneWidget);
    await t.tap(find.text('Hediye'));
    await t.tap(find.text('Oda Modu'));
    await t.tap(find.text('Konuş'));
    expect([gift, mode, mic], [1, 1, 1]);
  });

  testWidgets('PK sırasında mesaj satırı gizlenir, dock kalır', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceMockFooterView(
            presence: const [],
            toast: const SizedBox.shrink(),
            headphonesOn: true, sendEnabled: true, hideInput: true, userId: 'u',
            controller: TextEditingController(), focusNode: FocusNode(),
            micOn: true, micEnabled: true,
            onSend: () {}, onToggleAudioOutput: () {}, onMicToggle: () {},
            onGift: () {}, onEmojiTap: () {}, onChanged: (_) {},
                      onRoomMode: () {},
          ),
        ),
      ),
    );
    expect(find.text('Mesaj yaz... (istek)'), findsNothing);
    expect(find.text('Konuşuyor'), findsOneWidget);
  });
}
