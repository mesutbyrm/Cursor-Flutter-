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

  group('buildVoiceRoomCreatePayload', () {
    test('includes required production fields as JSON-ready map', () {
      final payload = LiveRemoteDataSource.buildVoiceRoomCreatePayload(
        roomType: 'normal',
        roomName: 'Test Oda',
      );
      expect(payload['name'], 'Test Oda');
      expect(payload['description'], isNotEmpty);
      expect(payload['icon'], isNotEmpty);
      expect(payload['nameTr'], payload['name']);
      expect(payload['descTr'], payload['description']);
      expect(payload['type'], 'voice');
      final room = payload['room'] as Map<String, dynamic>;
      expect(room['name'], payload['name']);
      expect(room['description'], payload['description']);
      expect(room['icon'], payload['icon']);
    });
  });
}
