import 'package:canlifal_social/features/live_psychics/data/models/psychic_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses production teller list item shape', () {
    final entity = PsychicModel.psychicFromJson({
      'id': 'cmokzl5u900w2od09rpqq2fs9',
      'userId': 'cmoks76yf00c4ph08ppcoqg98',
      'displayName': 'İlhamperisi',
      'applicationStatus': 'approved',
      'isOnline': true,
      'isActive': true,
      'isVerified': true,
      'pricePerSession': 100,
    });

    expect(entity.id, 'cmokzl5u900w2od09rpqq2fs9');
    expect(entity.userId, 'cmoks76yf00c4ph08ppcoqg98');
    expect(entity.applicationStatus, 'approved');
    expect(entity.isApproved, isTrue);
    expect(entity.isUsable, isTrue);
  });

  test('my-profile nested fortuneTeller key', () {
    final entity = PsychicModel.psychicFromMyProfileBody({
      'success': true,
      'teller': {
        'id': 'teller_abc',
        'userId': 'user_xyz',
        'displayName': 'Test Falcı',
        'applicationStatus': 'approved',
        'isOnline': true,
      },
    });

    expect(entity, isNotNull);
    expect(entity!.isUsable, isTrue);
  });

  test('infers approved from isActive when applicationStatus missing', () {
    final entity = PsychicModel.psychicFromJson({
      'id': 'teller_1',
      'userId': 'user_1',
      'displayName': 'A',
      'isActive': true,
      'isVerified': true,
    });

    expect(entity.applicationStatus, 'approved');
    expect(entity.isUsable, isTrue);
  });

  test('sessionHistoryFromJson parses client and teller', () {
    final entity = PsychicModel.sessionHistoryFromJson({
      'id': 'sess_abc',
      'fortuneType': 'tarot',
      'status': 'completed',
      'maxMinutes': 10,
      'minutesUsed': 8,
      'createdAt': '2025-06-17T12:00:00Z',
      'user': {'name': 'Mehmet K.'},
      'teller': {'displayName': 'Ayşe'},
    });

    expect(entity.sessionId, 'sess_abc');
    expect(entity.clientName, 'Mehmet K.');
    expect(entity.tellerName, 'Ayşe');
    expect(entity.maxMinutes, 10);
    expect(entity.minutesUsed, 8);
  });
}
