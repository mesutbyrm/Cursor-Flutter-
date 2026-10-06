import 'dart:async';

import 'package:canlifal_social/core/network/sse/sse_connection_hub.dart';
import 'package:canlifal_social/core/network/sse/sse_hub_lifecycle.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_room_background_recovery_spec.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Spec 20 — pause then debounced resume on SSE hub', (tester) async {
    final hub = SseConnectionHub();
    hub.attachVoiceRoom('room-bg');
    final binding = SseHubLifecycleBinding(hub);
    binding.attach();
    addTearDown(() {
      binding.dispose();
      unawaited(hub.dispose());
    });

    binding.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump();
    expect(hub.backgroundPaused, isTrue);

    binding.didChangeAppLifecycleState(AppLifecycleState.resumed);
    final debounce = VoiceRoomBackgroundRecoverySpec.sseHubResumeDebounce;
    await tester.pump(debounce - const Duration(milliseconds: 1));
    expect(hub.backgroundPaused, isTrue);

    await tester.pump(const Duration(milliseconds: 2));
    expect(hub.backgroundPaused, isFalse);
  });
}
