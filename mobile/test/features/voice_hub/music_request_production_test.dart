import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatRoomRemoteDataSource music query', () {
    test('skipMusicRequestByQueryEndpoint true for default canlifal.com', () {
      expect(ChatRoomRemoteDataSource.skipMusicRequestByQueryEndpoint, isTrue);
    });

    test('disableClientYoutubeSearch true on production host', () {
      expect(ChatRoomRemoteDataSource.disableClientYoutubeSearch, isTrue);
    });
  });
}
