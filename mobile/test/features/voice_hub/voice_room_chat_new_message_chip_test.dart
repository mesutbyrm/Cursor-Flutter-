import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_room/voice_room_chat_new_message_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows pending count in label', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceRoomChatNewMessageChip(
            pendingCount: 3,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Yeni mesaj (3)'), findsOneWidget);
    await tester.tap(find.byType(VoiceRoomChatNewMessageChip));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
