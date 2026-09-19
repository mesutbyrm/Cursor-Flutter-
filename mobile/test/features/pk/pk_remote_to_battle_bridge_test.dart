import 'package:canlifal_social/features/pk/data/pk_battle_bridge.dart';
import 'package:canlifal_social/features/pk/data/pk_models.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pkRemoteToBattle (voice chat-room PK → sheet battle)', () {
    test('pending voice invite maps id, rooms, opponent and status', () {
      final remote = PkBattleRemote(
        id: 'battle-1',
        inviteId: 'invite-1',
        battleType: 'voice_room',
        status: 'pending',
        challengerScore: 0,
        opponentScore: 0,
        secondsLeft: 180,
        durationSeconds: 180,
        targetScore: 150000,
        voiceRoomId: 'room_A',
        opponentVoiceRoomId: 'room_B',
        challengerId: 'u1',
        opponentId: 'u2',
        opponent: const PkParticipantRemote(userId: 'u2', displayName: 'Rakip'),
      );

      final battle = pkRemoteToBattle(remote);

      expect(battle.id, isNotEmpty);
      expect(battle.status, PkStatus.pending);
      expect(battle.room1Id, 'room_A');
      expect(battle.room2Id, 'room_B');
      expect(battle.user2Id, 'u2');
      expect(battle.user2?.name, 'Rakip');
      expect(battle.duration, 180);
    });

    test('opponent user id falls back to targetUserId/guestUserId', () {
      final remote = PkBattleRemote(
        id: 'b2',
        battleType: 'voice_room',
        status: 'pending',
        challengerScore: 0,
        opponentScore: 0,
        secondsLeft: 120,
        durationSeconds: 120,
        targetScore: 150000,
        voiceRoomId: 'room_A',
        opponentVoiceRoomId: 'room_B',
        guestUserId: 'guest-9',
      );

      final battle = pkRemoteToBattle(remote);
      expect(battle.user2Id, 'guest-9');
    });
  });
}
