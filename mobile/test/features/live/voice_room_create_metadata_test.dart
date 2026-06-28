import 'package:canlifal_social/features/live/data/datasources/live_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('voiceRoomCreateMetadata', () {
    test('normal room includes name, description and icon', () {
      final meta = LiveRemoteDataSource.voiceRoomCreateMetadata(
        roomType: 'normal',
        roomName: 'Test Oda',
      );
      expect(meta.name, 'Test Oda');
      expect(meta.description, 'Sesli sohbet odası');
      expect(meta.icon, '🎤');
    });

    test('vip room uses vip defaults', () {
      final meta = LiveRemoteDataSource.voiceRoomCreateMetadata(
        roomType: 'vip',
      );
      expect(meta.name, 'Sohbet');
      expect(meta.description, 'VIP sesli sohbet odası');
      expect(meta.icon, '⭐');
    });

    test('free room uses free defaults', () {
      final meta = LiveRemoteDataSource.voiceRoomCreateMetadata(
        roomType: 'free',
        roomName: '  ',
      );
      expect(meta.name, 'Sohbet');
      expect(meta.description, 'Ücretsiz sesli sohbet odası');
      expect(meta.icon, '🎙️');
    });

    test('truncates long names to 40 chars', () {
      final long = 'A' * 50;
      final meta = LiveRemoteDataSource.voiceRoomCreateMetadata(
        roomType: 'normal',
        roomName: long,
      );
      expect(meta.name.length, 40);
    });
  });

  group('resolveRoomTypeEnum', () {
    test('maps free and vip to uppercase enums', () {
      expect(
        LiveRemoteDataSource.resolveRoomTypeEnum('free'),
        'FREE',
      );
      expect(
        LiveRemoteDataSource.resolveRoomTypeEnum('normal'),
        'NORMAL',
      );
      expect(
        LiveRemoteDataSource.resolveRoomTypeEnum('vip'),
        'VIP',
      );
      expect(
        LiveRemoteDataSource.resolveRoomTypeEnum('normal', vip: true),
        'VIP',
      );
    });
  });

  group('normalizePaymentType', () {
    test('accepts jeton and cfc only', () {
      expect(LiveRemoteDataSource.normalizePaymentType('jeton'), 'jeton');
      expect(LiveRemoteDataSource.normalizePaymentType('cfc'), 'cfc');
      expect(LiveRemoteDataSource.normalizePaymentType('CFC'), 'cfc');
      expect(LiveRemoteDataSource.normalizePaymentType(null), 'jeton');
      expect(LiveRemoteDataSource.normalizePaymentType(''), 'jeton');
    });
  });

  group('buildVoiceRoomCreatePayload', () {
    test('matches web JSON.stringify(D) shape exactly', () {
      final payload = LiveRemoteDataSource.buildVoiceRoomCreatePayload(
        roomType: 'normal',
        roomName: 'Test Oda',
      );
      expect(payload.keys.toList(), [
        'name',
        'description',
        'icon',
        'paymentType',
        'roomType',
      ]);
      expect(payload['name'], 'Test Oda');
      expect(payload['description'], isNotEmpty);
      expect(payload['icon'], isNotEmpty);
      expect(payload['paymentType'], 'jeton');
      expect(payload['roomType'], 'NORMAL');
    });

    test('free room uses FREE roomType enum', () {
      final payload = LiveRemoteDataSource.buildVoiceRoomCreatePayload(
        roomType: 'free',
        roomName: 'Ücretsiz Oda',
      );
      expect(payload['roomType'], 'FREE');
      expect(payload['paymentType'], 'jeton');
    });

    test('vip room uses VIP roomType enum', () {
      final payload = LiveRemoteDataSource.buildVoiceRoomCreatePayload(
        roomType: 'vip',
        roomName: 'VIP Oda',
      );
      expect(payload['roomType'], 'VIP');
    });

    test('supports cfc paymentType', () {
      final payload = LiveRemoteDataSource.buildVoiceRoomCreatePayload(
        roomType: 'normal',
        paymentType: 'cfc',
      );
      expect(payload['paymentType'], 'cfc');
    });
  });
}
