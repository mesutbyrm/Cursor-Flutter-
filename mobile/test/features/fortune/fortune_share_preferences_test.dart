import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/fortune/data/fortune_share_preferences.dart';

void main() {
  test('FortuneAutoShareMode defaults to public when unset', () {
    expect(FortuneAutoShareMode.fromKey(null), FortuneAutoShareMode.public);
  });

  test('FortuneAutoShareMode respects explicit off', () {
    expect(FortuneAutoShareMode.fromKey('off'), FortuneAutoShareMode.off);
  });
}
