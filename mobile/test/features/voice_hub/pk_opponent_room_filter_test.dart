import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_opponent_room_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const self = VoiceRoomEntity(
    id: 'room-a',
    slug: 'room-a',
    nameTr: 'Oda A',
    ownerId: 'owner-a',
    onlineCount: 3,
  );

  const eligible = VoiceRoomEntity(
    id: 'room-b',
    slug: 'room-b',
    nameTr: 'Oda B',
    ownerId: 'owner-b',
    onlineCount: 5,
  );

  const emptyRoom = VoiceRoomEntity(
    id: 'room-c',
    slug: 'room-c',
    nameTr: 'Boş',
    ownerId: 'owner-c',
    onlineCount: 0,
  );

  const eligibleNoOwner = VoiceRoomEntity(
    id: 'room-d',
    slug: 'room-d',
    nameTr: 'Sahipsiz',
    onlineCount: 2,
  );

  test('filterPkEligibleOpponentRooms hides empty and self rooms', () {
    final out = filterPkEligibleOpponentRooms(
      [self, eligible, emptyRoom, eligibleNoOwner],
      excludeRoomKey: 'room-a',
    );
    expect(out.map((r) => r.id).toList(), ['room-b', 'room-d']);
  });

  test('isPkInviteTarget matches opponent user id', () {
    const battle = PkBattleRemote(
      id: 'pk1',
      battleType: 'voice_room',
      status: 'pending',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
      voiceRoomId: 'room-a',
      opponentId: 'owner-b',
    );
    expect(
      isPkInviteTarget(battle, eligible, userId: 'owner-b'),
      isTrue,
    );
    expect(
      isPkInviteTarget(battle, eligible, userId: 'other'),
      isTrue,
    );
    expect(isPkChallengerRoom(battle, self), isTrue);
  });

  test('isPkInviteTarget matches targetUserId and guestUserId', () {
    const battleTarget = PkBattleRemote(
      id: 'pk2',
      battleType: 'voice_room',
      status: 'invited',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
      voiceRoomId: 'room-a',
      targetUserId: 'owner-b',
    );
    expect(
      isPkInviteTarget(battleTarget, eligible, userId: 'owner-b'),
      isTrue,
    );

    const battleGuest = PkBattleRemote(
      id: 'pk3',
      battleType: 'voice_room',
      status: 'invited',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
      voiceRoomId: 'room-a',
      guestUserId: 'owner-b',
    );
    expect(
      isPkInviteTarget(battleGuest, eligible, userId: 'owner-b'),
      isTrue,
    );
  });

  test('isPkBattleLive only true for active battles', () {
    const pending = PkBattleRemote(
      id: 'pk1',
      battleType: 'voice_room',
      status: 'pending',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
    );
    const active = PkBattleRemote(
      id: 'pk2',
      battleType: 'voice_room',
      status: 'active',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
    );
    expect(isPkBattleLive(pending), isFalse);
    expect(isPkBattleLive(active), isTrue);
  });
}
