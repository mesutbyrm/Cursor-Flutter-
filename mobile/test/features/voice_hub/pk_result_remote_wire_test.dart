import 'package:canlifal_social/features/live/domain/pk/pk_status_helper.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isLivePkActiveStatus treats backend live as active', () {
    expect(isLivePkActiveStatus('live'), isTrue);
  });

  test('PkBattleRemote maps hostStreamId from pk/me/invites shape', () {
    final b = PkBattleRemote.fromJson({
      'id': 'pk-1',
      'status': 'pending',
      'hostStreamId': 'room-a',
      'guestStreamId': 'room-b',
      'hostScore': 0,
      'guestScore': 0,
      'durationSec': 180,
    });
    expect(b.voiceRoomId, 'room-a');
    expect(b.opponentVoiceRoomId, 'room-b');
    expect(b.status, 'pending');
  });

  test('PkResultRemote normalizes numeric winnerSide and host/guest result', () {
    final r1 = PkResultRemote.fromJson({
      'winnerSide': 1,
      'score1': 100,
      'score2': 50,
    });
    expect(r1.winnerSide, 'challenger');
    expect(r1.challengerFinalScore, 100);

    final r2 = PkResultRemote.fromJson({
      'result': 'guest',
      'isDraw': false,
      'score1': 10,
      'score2': 20,
    });
    expect(r2.winnerSide, 'opponent');
  });
}
