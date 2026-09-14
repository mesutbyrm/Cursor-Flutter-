import 'package:canlifal_social/features/pk/data/pk_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending cannot transition to completed via client rules', () {
    expect(pkTransitionAllowed(PkStatus.pending, PkStatus.completed), false);
    expect(pkTransitionAllowed(PkStatus.pending, PkStatus.cancelled), true);
    expect(pkTransitionAllowed(PkStatus.pending, PkStatus.rejected), true);
  });

  test('active can pause and complete', () {
    expect(pkTransitionAllowed(PkStatus.active, PkStatus.paused), true);
    expect(pkTransitionAllowed(PkStatus.active, PkStatus.completed), true);
  });
}
