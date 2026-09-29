import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/data/datasources/social_remote_datasource.dart';

void main() {
  test('backend yalnızca fortune/text/horoscope kabul eder', () {
    expect(socialPostTypeForBackend('fortune'), 'fortune');
    expect(socialPostTypeForBackend('horoscope'), 'horoscope');
    expect(socialPostTypeForBackend('image'), 'text');
    expect(socialPostTypeForBackend('video'), 'text');
    expect(socialPostTypeForBackend('text'), 'text');
  });
}
