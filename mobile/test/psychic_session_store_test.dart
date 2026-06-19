import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('PsychicSessionStore save and load roundtrip', () async {
    const session = PsychicSessionEntity(
      sessionId: 'sess_abc123',
      psychic: PsychicEntity(
        id: 'teller1',
        userId: 'user_teller',
        name: 'Ayşe',
        isOnline: true,
        pricePerMinute: 10,
      ),
      durationMinutes: 15,
      totalJeton: 150,
      tellerUserId: 'user_teller',
      clientId: 'user_client',
      isClient: true,
      fortuneType: 'tarot',
    );

    await PsychicSessionStore.save(session);
    final loaded = await PsychicSessionStore.load();

    expect(loaded, isNotNull);
    expect(loaded!.sessionId, session.sessionId);
    expect(loaded.psychic.id, 'teller1');
    expect(loaded.durationMinutes, 15);
    expect(loaded.fortuneType, 'tarot');

    await PsychicSessionStore.clear();
    expect(await PsychicSessionStore.load(), isNull);
  });
}
