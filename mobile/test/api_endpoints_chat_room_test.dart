import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat room extended endpoints match production paths', () {
    expect(
      ApiEndpoints.chatRoomMusicQueue('room1'),
      '/api/chat/rooms/room1/music-queue',
    );
    expect(
      ApiEndpoints.chatRoomSettings('room1'),
      '/api/chat/rooms/room1/settings',
    );
    expect(
      ApiEndpoints.chatRoomTransferOwnership('room1'),
      '/api/chat/rooms/room1/transfer-ownership',
    );
    expect(
      ApiEndpoints.chatRoomBannedWord('room1', 'kötü'),
      '/api/chat/rooms/room1/banned-words/k%C3%B6t%C3%BC',
    );
    expect(ApiEndpoints.userReceivedGifts, '/api/user/received-gifts');
    expect(ApiEndpoints.giftsCheckReciprocal, '/api/gifts/check-reciprocal');
  });
}
