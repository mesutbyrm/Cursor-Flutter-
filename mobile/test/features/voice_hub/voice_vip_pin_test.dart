import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/voice_vip_pin.dart';

void main() {
  test('VIP_PIN payload parses text and ttl', () {
    final pin = VoiceVipPin.fromPayload({
      'event': 'VIP_PIN',
      'text': 'Merhaba oda',
      'ttl': 90,
    });
    expect(pin?.text, 'Merhaba oda');
    expect(pin?.ttl, const Duration(seconds: 90));
  });

  test('missing ttl defaults to 60 s, oversized ttl is capped', () {
    expect(
      VoiceVipPin.fromPayload({'text': 'a'})?.ttl,
      VoiceVipPin.defaultTtl,
    );
    expect(
      VoiceVipPin.fromPayload({'text': 'a', 'ttl': '9999'})?.ttl,
      VoiceVipPin.maxTtl,
    );
  });

  test('empty text is ignored', () {
    expect(VoiceVipPin.fromPayload({'text': '  ', 'ttl': 30}), isNull);
  });
}
