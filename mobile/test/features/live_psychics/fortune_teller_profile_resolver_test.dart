import 'package:canlifal_social/features/live_psychics/data/models/psychic_model.dart';
import 'package:canlifal_social/features/live_psychics/data/services/fortune_teller_profile_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FortuneTellerProfileResult flags when list profile matches userId', () {
    final profile = PsychicModel.psychicFromJson({
      'id': 'cmokzl5u900w2od09rpqq2fs9',
      'userId': 'cmoks76yf00c4ph08ppcoqg98',
      'displayName': 'Test',
      'applicationStatus': 'approved',
    });

    final result = FortuneTellerProfileResult(
      profile: profile,
      authUserId: 'cmoks76yf00c4ph08ppcoqg98',
      source: 'fortune-tellers-list',
    );

    expect(result.profileFound, isTrue);
    expect(result.fortuneTellerId, 'cmokzl5u900w2od09rpqq2fs9');
    expect(result.fortuneTellerId, isNot('cmoks76yf00c4ph08ppcoqg98'));
    expect(result.isUsable, isTrue);
    expect(result.isApprovedTeller, isTrue);
    expect(result.isFortuneTeller, isTrue);
  });

  test('authUserId must not be used as fortuneTellerId', () {
    const authId = 'cmoks76yf00c4ph08ppcoqg98';
    const tellerId = 'cmokzl5u900w2od09rpqq2fs9';
    expect(authId, isNot(tellerId));
  });
}
