import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_music_submit.dart';

void main() {
  test('deferVoiceMusicSubmit runs submit on next microtask', () async {
    var microtaskReached = false;
    var submitRan = false;

    deferVoiceMusicSubmit(
      submit: () async {
        expect(microtaskReached, isTrue);
        submitRan = true;
        return null;
      },
      onComplete: (_) {},
    );

    microtaskReached = true;
    await Future<void>.delayed(Duration.zero);
    expect(submitRan, isTrue);
  });

  test('deferVoiceMusicSubmit forwards error message', () async {
    String? captured;

    deferVoiceMusicSubmit(
      submit: () async => throw Exception('network fail'),
      onComplete: (err) => captured = err,
    );

    await Future<void>.delayed(Duration.zero);
    expect(captured, isNotNull);
    expect(captured, contains('network'));
  });
}
