import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_room/voice_room_mention_notice_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mention banner shows countdown progress', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceRoomMentionNoticeBanner(
            dismissKey: 1,
            fromName: 'Ali',
            preview: 'Selam',
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('s'), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('mention banner pauses countdown while pointer is down', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceRoomMentionNoticeBanner(
            dismissKey: 2,
            fromName: 'Ayşe',
            preview: 'Merhaba',
            onDismiss: () {},
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('⏸'), findsNothing);

    final banner = find.byType(VoiceRoomMentionNoticeBanner);
    final center = tester.getCenter(banner);
    await tester.startGesture(center);
    await tester.pump();

    expect(find.text('⏸'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('⏸'), findsOneWidget);

    await tester.up();
    await tester.pump();

    expect(find.text('⏸'), findsNothing);
    expect(find.textContaining('s'), findsWidgets);
  });
}
