import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/live_psychics/data/models/psychic_model.dart';

void main() {
  test('psychicFromJson maps Sep10 fortune-tellers fields', () {
    final psychic = PsychicModel.psychicFromJson({
      'id': 't1',
      'displayName': 'Ayşe',
      'isOnline': true,
      'isGoldUser': true,
      'favoriteCount': 42,
      'presenceLabel': 'Meşgul',
      'isFavorited': true,
    });
    expect(psychic.id, 't1');
    expect(psychic.isGoldUser, isTrue);
    expect(psychic.favoriteCount, 42);
    expect(psychic.presenceLabel, 'Meşgul');
    expect(psychic.isFavorited, isTrue);
    expect(psychic.availabilityLabel, 'Meşgul');
  });
}
