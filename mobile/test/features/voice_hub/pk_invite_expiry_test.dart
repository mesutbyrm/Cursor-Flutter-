import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_invite_expiry.dart';

void main() {
  group('pkInviteSecondsLeft', () {
    test('uses expiresAt when present', () {
      final expiresAt = DateTime.now().add(const Duration(seconds: 45));
      final left = pkInviteSecondsLeft(expiresAt: expiresAt);
      expect(left, inInclusiveRange(44, 45));
    });

    test('falls back to timeoutSeconds', () {
      expect(pkInviteSecondsLeft(timeoutSeconds: 60), 60);
    });
  });

  group('isPkInviteExpireApiError', () {
    test('detects 400 timeout message', () {
      const err = ApiException(
        'PK isteği zaman aşımına uğradı (60 saniye)',
        statusCode: 400,
      );
      expect(isPkInviteExpireApiError(err), isTrue);
    });

    test('ignores other errors', () {
      const err = ApiException('Yetkisiz', statusCode: 403);
      expect(isPkInviteExpireApiError(err), isFalse);
    });
  });

  group('PkBattleRemote.withSseAction', () {
    test('maps expired action to status', () {
      const battle = PkBattleRemote(
        id: 'pk1',
        battleType: 'voice_room',
        status: 'pending',
        challengerScore: 0,
        opponentScore: 0,
        secondsLeft: 60,
        durationSeconds: 180,
        targetScore: 1000,
        expiresAt: null,
        timeoutSeconds: 60,
      );
      final next = battle.withSseAction('expired');
      expect(next.status, 'expired');
      expect(next.isExpired, isTrue);
    });

    test('maps started action to active', () {
      const battle = PkBattleRemote(
        id: 'pk1',
        battleType: 'voice_room',
        status: 'pending',
        challengerScore: 0,
        opponentScore: 0,
        secondsLeft: 60,
        durationSeconds: 180,
        targetScore: 1000,
      );
      expect(battle.withSseAction('started').status, 'active');
    });
  });
}
