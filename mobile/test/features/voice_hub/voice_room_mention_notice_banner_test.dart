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
}
