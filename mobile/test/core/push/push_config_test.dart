import 'package:canlifal_social/core/push/push_config.dart';
import 'package:canlifal_social/core/push/push_delivery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FCM-only default in test VM (dart-define yok)', () {
    expect(PushConfig.useFcmOnly, isTrue);
    expect(PushDelivery.usesOneSignal, isFalse);
  });
}
