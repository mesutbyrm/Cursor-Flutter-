import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_key_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomKeyResolver', () {
    const meta = VoiceRoomEntity(
      id: 'cmoohrbrx00a4nt08zlkdjyil',
      slug: 'canlfal-',
      nameTr: 'CanlıFal',
    );

    const rooms = [meta];

    test('partial cuid route resolves via known rooms list', () {
      expect(
        VoiceRoomKeyResolver.canonicalApiKey(
          routeKey: 'cmoohrbr',
          meta: const VoiceRoomEntity(id: 'cmoohrbr', slug: 'cmoohrbr', nameTr: 'Test'),
          knownRooms: rooms,
        ),
        'cmoohrbrx00a4nt08zlkdjyil',
      );
    });

    test('slug route resolves to prisma id for SSE', () {
      expect(
        VoiceRoomKeyResolver.canonicalApiKey(routeKey: 'canlfal-', meta: meta),
        'cmoohrbrx00a4nt08zlkdjyil',
      );
    });

    test('cuid route unchanged', () {
      expect(
        VoiceRoomKeyResolver.canonicalApiKey(
          routeKey: 'cmoohrbrx00a4nt08zlkdjyil',
          meta: meta,
        ),
        'cmoohrbrx00a4nt08zlkdjyil',
      );
    });

    test('unknown slug fallback keeps route key', () {
      const unknown = VoiceRoomEntity(
        id: 'short',
        slug: 'short',
        nameTr: 'Test',
      );
      expect(
        VoiceRoomKeyResolver.canonicalApiKey(routeKey: 'short', meta: unknown),
        'short',
      );
    });

    test('resolveFromKnownRooms matches id prefix', () {
      expect(
        VoiceRoomKeyResolver.resolveFromKnownRooms('cmoohrbr', rooms),
        'cmoohrbrx00a4nt08zlkdjyil',
      );
    });
  });
}
