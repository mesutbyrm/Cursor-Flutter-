import 'package:canlifal_social/features/live_psychics/data/models/psychic_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses production apply success wrapper', () {
    final entity = PsychicModel.psychicFromMyProfileBody({
      'success': true,
      'data': {
        'teller': {
          'id': 'pending-user_1',
          'userId': 'user_1',
          'displayName': 'Test',
          'applicationStatus': 'pending',
        },
      },
    });

    expect(entity, isNotNull);
    expect(entity!.applicationStatus, 'pending');
    expect(entity.isUsable, isFalse);
  });

  test('parses production my-profile teller root', () {
    final entity = PsychicModel.psychicFromMyProfileBody({
      'teller': {
        'id': 'cmokzl5u900w2od09rpqq2fs9',
        'userId': 'cmoks76yf00c4ph08ppcoqg98',
        'displayName': 'İlhamperisi',
        'applicationStatus': 'approved',
        'isActive': true,
      },
    });

    expect(entity, isNotNull);
    expect(entity!.isApproved, isTrue);
    expect(entity.isUsable, isTrue);
  });

  test('ignores auth error body for my-profile', () {
    expect(
      PsychicModel.psychicFromMyProfileBody({
        'error': 'Oturum açmanız gerekiyor',
      }),
      isNull,
    );
  });
}
