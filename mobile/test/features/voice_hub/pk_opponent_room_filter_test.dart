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

  test('filterPkEligibleOpponentRooms hides self and ownerless empty rooms', () {
    final out = filterPkEligibleOpponentRooms(
      [self, eligible, emptyRoom, eligibleNoOwner],
      excludeRoomKey: 'room-a',
    );
    expect(out.map((r) => r.id).toList(), ['room-b', 'room-d', 'room-c']);
  });

  test('isUserOwnedVoiceRoom matches ownerId or slug username', () {
    const slugOwned = VoiceRoomEntity(
      id: 'room-z',
      slug: 'myuser',
      nameTr: 'Slug Oda',
      onlineCount: 1,
    );
    expect(
      isUserOwnedVoiceRoom(slugOwned, userId: 'uid-1', username: 'myuser'),
      isTrue,
    );
    expect(
      isUserOwnedVoiceRoom(eligible, userId: 'owner-b', username: 'other'),
      isTrue,
    );
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

  test('isPkInviteTarget matches opponentVoiceRoomId', () {
    const battle = PkBattleRemote(
      id: 'pk4',
      battleType: 'voice_room',
      status: 'pending',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
      voiceRoomId: 'room-a',
      opponentVoiceRoomId: 'room-b',
    );
    expect(
      isPkInviteTarget(battle, eligible, userId: 'owner-b'),
      isTrue,
    );
    expect(
      isPkInviteTarget(battle, self, userId: 'owner-a'),
      isFalse,
    );
  });

  test('pickPkInviteTargetRoom prefers active room over other owned rooms', () {
    const roomC = VoiceRoomEntity(
      id: 'room-c',
      slug: 'room-c',
      nameTr: 'Oda C',
      ownerId: 'owner-b',
      onlineCount: 1,
    );
    const battle = PkBattleRemote(
      id: 'pk5',
      battleType: 'voice_room',
      status: 'pending',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
      voiceRoomId: 'room-a',
      opponentVoiceRoomId: 'room-b',
    );
    final rooms = [self, eligible, roomC];
    final picked = pickPkInviteTargetRoom(
      battle: battle,
      userId: 'owner-b',
      rooms: rooms,
      activeRoom: eligible,
    );
    expect(picked?.id, 'room-b');
  });

  test('pickPkInviteTargetRoom returns null when not pending', () {
    const battle = PkBattleRemote(
      id: 'pk6',
      battleType: 'voice_room',
      status: 'active',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
      voiceRoomId: 'room-a',
      opponentVoiceRoomId: 'room-b',
    );
    expect(
      pickPkInviteTargetRoom(
        battle: battle,
        userId: 'owner-b',
        rooms: [eligible],
        activeRoom: eligible,
      ),
      isNull,
    );
  });

  test('pkChallengerRoomLabelFromRooms prefers room name', () {
    const battle = PkBattleRemote(
      id: 'pk7',
      battleType: 'voice_room',
      status: 'pending',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
      voiceRoomId: 'room-a',
    );
    expect(
      pkChallengerRoomLabelFromRooms(battle, [self, eligible]),
      'Oda A',
    );
  });

  test('pkChallengerRoomLabelFromRooms falls back to challenger display name', () {
    const battle = PkBattleRemote(
      id: 'pk8',
      battleType: 'voice_room',
      status: 'pending',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
      voiceRoomId: 'unknown-room',
      challenger: PkParticipantRemote(
        userId: 'u1',
        displayName: 'Meydan Okuyan',
      ),
    );
    expect(
      pkChallengerRoomLabelFromRooms(battle, [eligible]),
      'Meydan Okuyan',
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
