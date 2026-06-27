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
}
