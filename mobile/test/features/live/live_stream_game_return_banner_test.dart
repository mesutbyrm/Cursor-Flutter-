import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_stream_game_return_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LiveStreamGameReturnBanner shows return hint', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveStreamGameReturnBanner(
            streamId: 'stream-1',
            gameRoomId: 'room-9',
          ),
        ),
      ),
    );
    expect(find.text('Canlı yayın devam ediyor'), findsOneWidget);
    expect(find.textContaining('yayına geri dön'), findsOneWidget);
  });

  testWidgets('LiveStreamGameReturnBanner hidden for empty streamId', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveStreamGameReturnBanner(streamId: ''),
        ),
      ),
    );
    expect(find.text('Canlı yayın devam ediyor'), findsNothing);
  });
}
