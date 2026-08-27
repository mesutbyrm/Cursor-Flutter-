import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/data/services/live_namespace_socket_service.dart';

void main() {
  test('LiveNamespaceSocketService does not open Socket.IO', () {
    final svc = LiveNamespaceSocketService();
    var connectedFlag = false;
    svc.connect(
      accessToken: () async => 'token',
      streamId: 'stream-1',
      onConnectionChanged: (c) => connectedFlag = c,
    );
    expect(svc.connected, isFalse);
    expect(connectedFlag, isFalse);
    svc.updateRooms(streamId: 'stream-1', battleId: 'battle-1');
    svc.disconnect();
    expect(svc.connected, isFalse);
  });
}
