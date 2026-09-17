import 'package:canlifal_social/core/motion/canlifal_motion_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stagger caps delay', () {
    expect(CanlifalMotionTokens.staggerIndex(0), Duration.zero);
    expect(CanlifalMotionTokens.staggerIndex(10), const Duration(milliseconds: 200));
  });
}
