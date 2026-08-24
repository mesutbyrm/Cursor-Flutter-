import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_music_submit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deferVoiceMusicSubmit waits for sheet-close delay before submit', () async {
    var submitRan = false;

    deferVoiceMusicSubmit(
      submit: () async {
        submitRan = true;
        return null;
      },
      onComplete: (_) {},
    );

    await Future<void>.delayed(Duration.zero);
    expect(submitRan, isFalse);

    await Future<void>.delayed(
      const Duration(milliseconds: kVoiceMusicSubmitDeferMs + 50),
    );
    expect(submitRan, isTrue);
  });

  test('deferVoiceMusicSubmit forwards error message', () async {
    String? captured;

    deferVoiceMusicSubmit(
      submit: () async => throw Exception('network fail'),
      onComplete: (err) => captured = err,
    );

    await Future<void>.delayed(
      const Duration(milliseconds: kVoiceMusicSubmitDeferMs + 50),
    );
    expect(captured, isNotNull);
    expect(captured, contains('network'));
  });
}
