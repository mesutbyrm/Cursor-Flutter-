import 'package:canlifal_social/core/push/push_delivery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FCM-only: OneSignal inactive in default test build', () {
    expect(PushDelivery.oneSignalActive, isFalse);
  });
}
