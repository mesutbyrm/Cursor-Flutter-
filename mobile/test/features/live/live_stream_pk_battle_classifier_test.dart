import 'package:canlifal_social/features/live/domain/pk/live_pk_invite_helper.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voice room PK with stream1Id is not live stream PK', () {
    const battle = PkBattleRemote(
      id: 'pk1',
      battleType: 'voice_room',
      status: 'pending',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 60,
      durationSeconds: 180,
      targetScore: 1000,
      voiceRoomId: 'room-a',
      opponentVoiceRoomId: 'room-b',
      liveStreamId: 'room-a',
      opponentLiveStreamId: 'room-b',
    );
    expect(isLiveStreamPkBattle(battle), isFalse);
  });
}
