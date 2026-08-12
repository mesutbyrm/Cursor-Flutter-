import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_opponent_room_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const room = VoiceRoomEntity(
    id: 'room-a',
    slug: 'room-a-slug',
    nameTr: 'Oda A',
  );

  test('pkBattleBelongsToRoom matches challenger room id', () {
    const battle = PkBattleRemote(
      id: 'pk1',
      battleType: 'voice',
      status: 'active',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 60,
      durationSeconds: 180,
      targetScore: 100,
      voiceRoomId: 'room-a',
      opponentVoiceRoomId: 'room-b',
    );
    expect(pkBattleBelongsToRoom(battle, room), isTrue);
  });

  test('pkBattleBelongsToRoom rejects unrelated room', () {
    const battle = PkBattleRemote(
      id: 'pk2',
      battleType: 'voice',
      status: 'active',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 60,
      durationSeconds: 180,
      targetScore: 100,
      voiceRoomId: 'room-x',
      opponentVoiceRoomId: 'room-y',
    );
    expect(pkBattleBelongsToRoom(battle, room), isFalse);
  });
}
