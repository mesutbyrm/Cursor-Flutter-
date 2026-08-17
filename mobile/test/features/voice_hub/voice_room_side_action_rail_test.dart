import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_room/voice_room_side_action_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VoiceRoomSideActionRail centers on right edge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const VoiceRoomSideActionRail(
                onSettings: _noop,
                onMusic: _noop,
              ),
            ],
          ),
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.top, 0);
    expect(positioned.bottom, 0);
    expect(positioned.right, 8);

    final align = tester.widget<Align>(find.byType(Align));
    final alignment = align.alignment as Alignment;
    expect(alignment.x, 1);
    expect(alignment.y, closeTo(0.12, 0.001));
  });
}

void _noop() {}
