import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_room/voice_room_typing_indicator.dart';

void main() {
  testWidgets('VoiceRoomTypingIndicator shows single user label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VoiceRoomTypingIndicator(userNames: ['Ayşe']),
        ),
      ),
    );
    expect(find.text('Ayşe yazıyor'), findsOneWidget);
  });

  testWidgets('VoiceRoomTypingIndicator pluralizes multiple users', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VoiceRoomTypingIndicator(userNames: ['A', 'B', 'C']),
        ),
      ),
    );
    expect(find.text('A ve 2 kişi yazıyor'), findsOneWidget);
  });
}
