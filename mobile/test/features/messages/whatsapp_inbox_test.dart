import 'package:canlifal_social/features/messages/data/models/conversation_dto.dart';
import 'package:canlifal_social/features/messages/domain/entities/message_entities.dart';
import 'package:canlifal_social/features/messages/domain/utils/last_seen_format.dart';
import 'package:canlifal_social/features/messages/presentation/widgets/chat_message_bubble.dart';
import 'package:canlifal_social/features/messages/presentation/widgets/conversation_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  group('presenceLabel', () {
    final now = DateTime(2026, 10, 10, 15, 0);

    test('çevrimiçi', () {
      expect(presenceLabel(isOnline: true, lastSeenAt: DateTime(2026, 10, 10, 9), now: now), 'çevrimiçi');
    });

    test('veri yoksa uydurma metin yok', () {
      expect(presenceLabel(isOnline: false, lastSeenAt: null, now: now), '');
    });

    test('bugün / dün / tarih', () {
      expect(presenceLabel(isOnline: false, lastSeenAt: DateTime(2026, 10, 10, 14, 5), now: now), 'son görülme bugün 14:05');
      expect(presenceLabel(isOnline: false, lastSeenAt: DateTime(2026, 10, 9, 23, 59), now: now), 'son görülme dün 23:59');
      expect(presenceLabel(isOnline: false, lastSeenAt: DateTime(2026, 3, 2, 8, 0), now: now), startsWith('son görülme 2 Mar'));
    });
  });

  group('ConversationDto presence', () {
    test('sunucu isOnline + lastSeenAt alanlarını okur', () {
      final e = ConversationDto.fromApiMap({
        'id': 'c1',
        'user': {'id': 'u1', 'name': 'Ayşe'},
        'lastMessage': 'Selam',
        'isOnline': false,
        'lastSeenAt': '2026-10-10T10:00:00.000Z',
      }).toEntity();
      expect(e.isOnline, isFalse);
      expect(e.lastSeenAt, DateTime.utc(2026, 10, 10, 10).toLocal());
    });

    test('çevrimiçiyken son görülme taşınmaz; alan yoksa null', () {
      final online = ConversationDto.fromApiMap({
        'user': {'id': 'u1', 'name': 'Ayşe'},
        'isOnline': true,
        'lastSeenAt': '2026-10-10T10:00:00.000Z',
      }).toEntity();
      expect(online.isOnline, isTrue);
      expect(online.lastSeenAt, isNull);

      final old = ConversationDto.fromApiMap({'user': {'id': 'u2', 'name': 'Ali'}}).toEntity();
      expect(old.isOnline, isFalse);
      expect(old.lastSeenAt, isNull);
    });
  });

  Widget host(Widget child, {Brightness b = Brightness.dark}) => ProviderScope(
        child: MaterialApp(
          theme: ThemeData(brightness: b),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  testWidgets('satır: isim, önizleme, rozet; yeşil nokta yalnız çevrimiçiyken', (t) async {
    await t.pumpWidget(host(Column(children: [
      ConversationTile(
        conversation: const ConversationEntity(id: 'a', title: 'Şükrü Öztürk', subtitle: 'Görüşürüz', unreadCount: 3, isOnline: true),
        onTap: () {},
      ),
      ConversationTile(
        conversation: const ConversationEntity(id: 'b', title: 'İpek', subtitle: 'Tamam'),
        onTap: () {},
      ),
    ])));
    expect(find.text('Şükrü Öztürk'), findsOneWidget);
    expect(find.text('Görüşürüz'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('çevrimiçi'), findsOneWidget);
    expect(find.byKey(const Key('presence-online-dot')), findsOneWidget);
    expect(find.textContaining('son görülme'), findsNothing);
  });

  testWidgets('balon: benim mesajım sağda, karşı taraf solda; tik yalnız bende', (t) async {
    await t.pumpWidget(host(Column(children: [
      ChatMessageBubble(
        message: MessageEntity(id: '1', text: 'Benim', isMine: true, createdAt: DateTime(2026, 10, 10, 12), deliveryStatus: MessageDeliveryStatus.read),
      ),
      ChatMessageBubble(message: MessageEntity(id: '2', text: 'Onun', isMine: false, createdAt: DateTime(2026, 10, 10, 12))),
    ]), b: Brightness.light));
    final w = t.getSize(find.byType(Scaffold)).width;
    expect(t.getCenter(find.text('Benim')).dx, greaterThan(w / 2));
    expect(t.getCenter(find.text('Onun')).dx, lessThan(w / 2));
    expect(find.byType(MessageReadTicks), findsOneWidget);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
    // Açık temada karşı taraf metni okunur koyu renkte.
    final onun = t.widget<Text>(find.text('Onun'));
    expect(onun.style?.color, const Color(0xFF111B21));
  });
}
