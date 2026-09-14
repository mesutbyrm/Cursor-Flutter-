import 'package:canlifal_social/features/pk/data/pk_models.dart';
import 'package:canlifal_social/features/pk/data/pk_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseUnwrappedBattle reads zarfsiz video-streams body', () {
    final battle = PkService.parseUnwrappedBattle({
      'id': 'pk1',
      'status': 'pending',
      'score1': 10,
      'score2': 5,
    });
    expect(battle?.id, 'pk1');
    expect(battle?.status, PkStatus.pending);
    expect(battle?.score1, 10);
  });

  test('PkException maps NOT_STREAM_OWNER', () {
    final msg = PkException.userMessageForCode('NOT_STREAM_OWNER', 'x');
    expect(msg, 'PK başlatma yetkiniz yok');
  });
}
