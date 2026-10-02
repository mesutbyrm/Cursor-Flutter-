import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/vip_gold/domain/voice_room_access.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_ban_entry.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_violation.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/girlive_rules_notice_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/premium/voice_mgmt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

VoiceRoomEntity _room({String? type, String name = 'Oda'}) => VoiceRoomEntity(
      id: 'r1',
      slug: 'oda',
      nameTr: name,
      roomType: type,
    );

void main() {
  group('VoiceMgmtCard', () {
    testWidgets('başlık, açıklama ve chevron gösterir; dokununca çalışır',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceMgmtCard(
              icon: Icons.people_alt_rounded,
              title: 'Kullanıcı Yönetimi',
              subtitle: 'Kısa açıklama',
              onTap: () => taps++,
            ),
          ),
        ),
      );
      expect(find.text('Kullanıcı Yönetimi'), findsOneWidget);
      expect(find.text('Kısa açıklama'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.tap(find.text('Kullanıcı Yönetimi'));
      expect(taps, 1);
    });

    testWidgets('kilitli kart kilit ikonu gösterir ama dokunma çalışır',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceMgmtCard(
              icon: Icons.home_work_rounded,
              title: 'Oda Yönetimi',
              subtitle: 'x',
              locked: true,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_work_rounded), findsNothing);
      await tester.tap(find.text('Oda Yönetimi'));
      expect(taps, 1);
    });
  });

  group('isStrictVipRoom', () {
    test('yalnızca roomType VIP olan oda VIP sayılır', () {
      expect(_room(type: 'VIP').isStrictVipRoom, isTrue);
      expect(_room(type: 'vip').isStrictVipRoom, isTrue);
      expect(_room(type: 'NORMAL').isStrictVipRoom, isFalse);
      expect(_room(type: 'FREE').isStrictVipRoom, isFalse);
      expect(_room().isStrictVipRoom, isFalse);
    });

    test('adında VIP geçen normal oda şifrelenemez', () {
      final r = _room(type: 'NORMAL', name: 'VIP Sohbet');
      expect(r.isStrictVipRoom, isFalse);
    });
  });

  test('VoiceRoomBanEntry bitiş zamanını okur', () {
    final future = DateTime.now().add(const Duration(hours: 2));
    final b = VoiceRoomBanEntry.fromJson({
      'id': 'b1',
      'userId': 'u1',
      'expiresAt': future.toUtc().toIso8601String(),
    });
    expect(b.expiresAt, isNotNull);
    expect(b.expiresAt!.isAfter(DateTime.now()), isTrue);
    final perm = VoiceRoomBanEntry.fromJson({'id': 'b2', 'userId': 'u2'});
    expect(perm.expiresAt, isNull);
  });

  group('GirLive Bot', () {
    test('ihlal kaydı ayrıştırılır', () {
      final v = VoiceRoomViolation.fromJson({
        'id': 'v1',
        'userId': 'u1',
        'severity': 'MEDIUM',
        'action': 'mute',
        'word': 'amk',
        'createdAt': '2026-10-02T10:00:00.000Z',
        'expiresAt': '2026-10-02T10:05:00.000Z',
        'user': {'id': 'u1', 'name': 'Ali', 'username': 'ali'},
      });
      expect(v.userLabel, '@ali');
      expect(v.actionLabel, 'Sessize alındı');
      expect(v.isWarning, isFalse);
      expect(v.expiresAt, isNotNull);
      final w = VoiceRoomViolation.fromJson({'id': 'v2', 'action': 'warn'});
      expect(w.isWarning, isTrue);
      expect(w.userLabel, 'Kullanıcı');
    });

    test('kural bildirimi boş metinle tetiklenmez, her gösterim yeni nonce alır', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(girLiveRulesNoticeProvider.notifier);
      n.show('   ');
      expect(c.read(girLiveRulesNoticeProvider), isNull);
      n.show('Kurallara uyun');
      final first = c.read(girLiveRulesNoticeProvider)!;
      n.show('Kurallara uyun');
      expect(c.read(girLiveRulesNoticeProvider)!.nonce, greaterThan(first.nonce));
    });
  });
}
