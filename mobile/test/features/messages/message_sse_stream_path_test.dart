import 'package:canlifal_social/core/config/env.dart';
import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile auth uses peer message stream path', () {
    expect(Env.useMobileAuth, isTrue);
    expect(
      ApiEndpoints.messagesStreamWithUser('user-abc'),
      '/api/messages/user-abc/stream',
    );
  });
}
