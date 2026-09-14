import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_broadcast_room_bottom_chrome.dart';
import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_broadcast_room_chat_overlay.dart';
import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_broadcast_room_video_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live room extraction modules are defined', () {
    expect(LiveBroadcastRoomVideoLayer, isNotNull);
    expect(LiveBroadcastRoomChatOverlay, isNotNull);
    expect(LiveBroadcastRoomBottomChrome, isNotNull);
  });
}
