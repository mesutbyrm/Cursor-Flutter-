import 'package:canlifal_social/features/live/domain/pk/live_pk_invite_helper.dart';
import 'package:canlifal_social/features/live/domain/pk/pk_room_models.dart';
import 'package:canlifal_social/features/live/domain/pk/pk_status_helper.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isPkInvitePendingStatus accepts pending and invited', () {
    expect(isPkInvitePendingStatus('pending'), isTrue);
    expect(isPkInvitePendingStatus('invited'), isTrue);
    expect(isPkInvitePendingStatus('active'), isFalse);
  });

  test('PkRoomMatch.isPending includes invited', () {
    const pending = PkRoomMatch(
      id: 'm1',
      mode: PkRoomMode.oneVsOne,
      status: 'pending',
    );
    const invited = PkRoomMatch(
      id: 'm2',
      mode: PkRoomMode.oneVsOne,
      status: 'invited',
    );
    expect(pending.isPending, isTrue);
    expect(invited.isPending, isTrue);
  });

  test('PkBattleRemote.isPending includes invited', () {
    const battle = PkBattleRemote(
      id: 'pk1',
      battleType: 'voice_room',
      status: 'invited',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 300,
      durationSeconds: 180,
      targetScore: 1000,
    );
    expect(battle.isPending, isTrue);
  });

  test('isLivePkInviteRecipientMap accepts invited status', () {
    expect(
      isLivePkInviteRecipientMap(
        {
          'status': 'invited',
          'hostUserId': 'host',
          'opponentUserId': 'guest',
        },
        myStreamId: '',
        myUserId: 'guest',
      ),
      isTrue,
    );
  });
}
