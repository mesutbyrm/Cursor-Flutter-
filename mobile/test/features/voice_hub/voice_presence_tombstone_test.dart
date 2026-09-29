import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_presence_tombstone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filter removes tombstoned user until TTL expires', () {
    final tomb = VoicePresenceTombstone(ttl: const Duration(minutes: 5));
    final t0 = DateTime(2026, 9, 29, 12, 0);
    tomb.mark('u1', now: t0);

    final users = [
      const ChatRoomPresence(id: 'u1', name: 'Ghost'),
      const ChatRoomPresence(id: 'u2', name: 'Real'),
    ];

    expect(
      tomb.filter(users, now: t0.add(const Duration(minutes: 1))).map((e) => e.id),
      ['u2'],
    );
    expect(
      tomb.filter(users, now: t0.add(const Duration(minutes: 6))).map((e) => e.id),
      ['u1', 'u2'],
    );
  });

  test('clear resets tombstones', () {
    final tomb = VoicePresenceTombstone();
    tomb.mark('u1');
    tomb.clear();
    final users = [const ChatRoomPresence(id: 'u1', name: 'Back')];
    expect(tomb.filter(users).length, 1);
  });
}
