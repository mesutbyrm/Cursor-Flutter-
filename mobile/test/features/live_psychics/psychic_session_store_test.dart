import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const session = PsychicSessionEntity(
    sessionId: 'sess_store_1',
    psychic: PsychicEntity(
      id: 'teller_store',
      userId: 'user_teller',
      name: 'Store Falcı',
      bio: 'Bio metni',
      avatarUrl: 'https://cdn.example/avatar.png',
      isOnline: true,
      rating: 4.8,
      reviewCount: 12,
      pricePerMinute: 10,
      specialties: const ['tarot', 'kahve'],
      category: 'spiritual',
      applicationStatus: 'approved',
    ),
    durationMinutes: 15,
    totalJeton: 150,
    tellerUserId: 'user_teller',
    clientId: 'user_client',
    isClient: true,
    trtcRoomIdOverride: 'room_override',
    fortuneType: 'tarot',
  );

  group('PsychicSessionStore', () {
    test('save and load roundtrip preserves session fields', () async {
      await PsychicSessionStore.save(session);
      final loaded = await PsychicSessionStore.load();

      expect(loaded, isNotNull);
      expect(loaded!.sessionId, session.sessionId);
      expect(loaded.durationMinutes, 15);
      expect(loaded.totalJeton, 150);
      expect(loaded.tellerUserId, 'user_teller');
      expect(loaded.clientId, 'user_client');
      expect(loaded.isClient, isTrue);
      expect(loaded.trtcRoomIdOverride, 'room_override');
      expect(loaded.fortuneType, 'tarot');
      expect(loaded.psychic.id, 'teller_store');
      expect(loaded.psychic.name, 'Store Falcı');
      expect(loaded.psychic.specialties, ['tarot', 'kahve']);
      expect(loaded.psychic.rating, 4.8);
    });

    test('load returns null when store is empty', () async {
      expect(await PsychicSessionStore.load(), isNull);
    });

    test('clear removes persisted session', () async {
      await PsychicSessionStore.save(session);
      await PsychicSessionStore.clear();
      expect(await PsychicSessionStore.load(), isNull);
    });

    test('load returns null for invalid json', () async {
      SharedPreferences.setMockInitialValues({
        'live_psychics_active_session_v1': 'not-json',
      });
      expect(await PsychicSessionStore.load(), isNull);
    });

    test('load returns null when sessionId missing', () async {
      SharedPreferences.setMockInitialValues({
        'live_psychics_active_session_v1':
            '{"psychic":{"id":"t1","name":"X"}}',
      });
      expect(await PsychicSessionStore.load(), isNull);
    });

    test('load returns null when psychic id missing', () async {
      SharedPreferences.setMockInitialValues({
        'live_psychics_active_session_v1':
            '{"sessionId":"s1","psychic":{"name":"X"}}',
      });
      expect(await PsychicSessionStore.load(), isNull);
    });

    test('save overwrites previous session', () async {
      await PsychicSessionStore.save(session);
      const updated = PsychicSessionEntity(
        sessionId: 'sess_store_2',
        psychic: PsychicEntity(id: 'teller_2', name: 'Yeni', isOnline: false),
        durationMinutes: 10,
        totalJeton: 100,
      );
      await PsychicSessionStore.save(updated);

      final loaded = await PsychicSessionStore.load();
      expect(loaded?.sessionId, 'sess_store_2');
      expect(loaded?.psychic.name, 'Yeni');
    });
  });
}
