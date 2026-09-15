import 'package:canlifal_social/features/pk/data/pk_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PkCandidate.fromStreamJson resolves targetRoomId', () {
    final c = PkCandidate.fromStreamJson({
      'targetRoomId': 'stream-abc',
      'name': 'Mert',
      'viewers': 3,
    });
    expect(c.contextId, 'stream-abc');
    expect(c.name, 'Mert');
    expect(c.viewers, 3);
  });

  test('PkCandidate.fromRoomJson resolves streamId fallback', () {
    final c = PkCandidate.fromRoomJson({
      'streamId': 'room-x',
      'name': 'Oda',
    });
    expect(c.contextId, 'room-x');
  });
}
