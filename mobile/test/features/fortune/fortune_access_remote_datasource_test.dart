import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fortune jeton preflight uses canonical check endpoint', () {
    expect(ApiEndpoints.fortuneAccessCheck, '/api/fortune-access/check');
    expect(
      ApiEndpoints.fortuneAccessCheck,
      isNot(contains('/consume')),
    );
  });
}
