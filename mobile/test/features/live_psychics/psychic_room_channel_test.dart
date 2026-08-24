import 'package:flutter_test/flutter_test.dart';

/// Mirrors [PsychicVideoController._canonicalRoomChannel] for regression tests.
String canonicalPsychicRoomChannel({
  required String sessionId,
  String? raw,
}) {
  final id = raw?.trim() ?? '';
  if (id.isEmpty) return sessionId.trim();
  final base = sessionId.trim();
  if (id == base || id == 'room_$base') return base;
  if (id.startsWith('room_')) return id.substring(5);
  return id;
}

void main() {
  group('canonicalPsychicRoomChannel', () {
    const sessionId = 'sess-abc';

    test('empty raw falls back to session id', () {
      expect(
        canonicalPsychicRoomChannel(sessionId: sessionId, raw: null),
        sessionId,
      );
    });

    test('room_ prefix normalizes to same channel', () {
      expect(
        canonicalPsychicRoomChannel(sessionId: sessionId, raw: 'room_$sessionId'),
        sessionId,
      );
    });

    test('distinct backend room id stays distinct', () {
      expect(
        canonicalPsychicRoomChannel(sessionId: sessionId, raw: 'room_xyz'),
        'xyz',
      );
    });
  });
}
