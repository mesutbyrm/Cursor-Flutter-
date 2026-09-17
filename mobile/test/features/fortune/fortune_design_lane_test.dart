import 'package:canlifal_social/features/fortune/presentation/design/fortune_design_lane.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FortuneLaneMotion aligns with CDS durations', () {
    expect(FortuneLaneMotion.cardEnter.inMilliseconds, 150);
    expect(FortuneLaneMotion.standard.inMilliseconds, 250);
    expect(FortuneLaneMotion.emphasis.inMilliseconds, 420);
  });
}
