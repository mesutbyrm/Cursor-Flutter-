import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/presentation/pages/voice_room_owner_manage_page.dart';
import 'package:canlifal_social/features/voice_hub/presentation/pages/voice_room_owner_summary_page.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_session_visitors_provider.dart';

void main() {
  group('ownerSessionEarningsFromTransactions', () {
    final start = DateTime(2026, 9, 28, 20);

    test('sums owner share and received gifts for this room after start', () {
      final total = ownerSessionEarningsFromTransactions(
        since: start,
        roomTitle: 'Gece Sohbeti',
        txs: [
          (amount: 40, type: 'gift_commission', description: 'Oda sahibi payı: Gül (Gece Sohbeti)', at: start.add(const Duration(minutes: 5))),
          (amount: 100, type: 'gift_received', description: 'Ali tarafından Gül hediyesi alındı (Gece Sohbeti)', at: start.add(const Duration(minutes: 9))),
          // önceki oturum
          (amount: 500, type: 'gift_commission', description: 'Oda sahibi payı: Aslan (Gece Sohbeti)', at: start.subtract(const Duration(hours: 1))),
          // başka oda
          (amount: 70, type: 'gift_commission', description: 'Oda sahibi payı: Gül (Müzik Odası)', at: start.add(const Duration(minutes: 3))),
          // harcama / başka tür
          (amount: -20, type: 'gift_sent', description: 'Gece Sohbeti', at: start.add(const Duration(minutes: 1))),
          (amount: 30, type: 'daily_bonus', description: 'Gece Sohbeti', at: start.add(const Duration(minutes: 1))),
        ],
      );
      expect(total, 140);
    });
  });

  group('VoiceSessionVisitorsNotifier', () {
    ChatRoomPresence p(String id, String name) =>
        ChatRoomPresence(id: id, name: name);

    test('records unique visitors except me and resets on take', () {
      final n = VoiceSessionVisitorsNotifier()..start('room1');
      n.record('room1', [p('me', 'Ben'), p('a', 'Ayşe')], myUserId: 'me');
      n.record('room1', [p('a', 'Ayşe'), p('b', 'Berk')], myUserId: 'me');
      n.record('other', [p('c', 'Can')], myUserId: 'me');

      final snap = n.takeAndReset('room1');
      expect(snap!.visitors.keys, ['a', 'b']);
      expect(n.state, isNull);
    });

    test('start always begins a fresh session', () {
      final n = VoiceSessionVisitorsNotifier()..start('room1');
      n.record('room1', [p('a', 'Ayşe')]);
      n.start('room1');
      expect(n.state!.visitors, isEmpty);
    });
  });

  group('OwnerRoomSettings.fromJson', () {
    test('parses server settings fields', () {
      final s = OwnerRoomSettings.fromJson({
        'nameTr': 'Gece Sohbeti',
        'descTr': 'Hoş geldiniz',
        'tags': 'music,love',
        'password': 'x1234',
        'seatCount': 12,
        'isMuted': false,
        'djUserIds': '["u1","u2"]',
        'giftCommissionPercent': 10,
        'welcomeMessage': null,
      });
      expect(s.name, 'Gece Sohbeti');
      expect(s.category, 'music');
      expect(s.hasPassword, isTrue);
      expect(s.seatCount, 12);
      expect(s.djUserIds, ['u1', 'u2']);
      expect(s.commissionPercent, 10);
      expect(s.welcomeMessage, isNull);
    });

    test('no password and no tags', () {
      final s = OwnerRoomSettings.fromJson({'nameTr': 'A', 'password': null});
      expect(s.hasPassword, isFalse);
      expect(s.category, isNull);
      expect(s.djUserIds, isEmpty);
    });
  });
}
