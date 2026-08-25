import 'package:canlifal_social/features/trtc/domain/trtc_reconnect_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connected session does not hard-reconnect', () {
    final gate = TrtcReconnectGate(sdkGrace: const Duration(milliseconds: 1));
    gate.onJoinStarted();
    gate.onConnecting();
    gate.onConnected();
    expect(gate.phase, TrtcConnectionPhase.connected);
    expect(gate.shouldHardReconnect, isFalse);
  });

  test('onConnectionLost waits for SDK grace before hard reconnect', () {
    final gate = TrtcReconnectGate(sdkGrace: const Duration(seconds: 8));
    gate.onJoinStarted();
    gate.onConnecting();
    gate.onConnected();
    gate.onSdkConnectionLost();
    expect(gate.phase, TrtcConnectionPhase.reconnecting);
    expect(gate.shouldHardReconnect, isFalse);
  });

  test('SDK recovery cancels hard reconnect', () {
    final gate = TrtcReconnectGate(sdkGrace: const Duration(milliseconds: 1));
    gate.onJoinStarted();
    gate.onConnecting();
    gate.onConnected();
    gate.onSdkConnectionLost();
    gate.onSdkTryToReconnect();
    gate.onSdkRecovered();
    expect(gate.phase, TrtcConnectionPhase.connected);
    expect(gate.shouldHardReconnect, isFalse);
  });

  test('second hard reconnect is blocked while one is in flight', () async {
    final gate = TrtcReconnectGate(sdkGrace: const Duration(milliseconds: 15));
    gate.onJoinStarted();
    gate.onConnecting();
    gate.onConnected();
    gate.onSdkConnectionLost();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(gate.shouldHardReconnect, isTrue);
    gate.markHardReconnectStarted();
    expect(gate.shouldHardReconnect, isFalse);
    gate.onHardReconnectFinished(success: true);
    expect(gate.phase, TrtcConnectionPhase.connected);
    expect(gate.shouldHardReconnect, isFalse);
  });

  test('closed phase ignores later lost events', () {
    final gate = TrtcReconnectGate();
    gate.onJoinStarted();
    gate.onConnecting();
    gate.onConnected();
    gate.onClosed();
    gate.onSdkConnectionLost();
    expect(gate.phase, TrtcConnectionPhase.closed);
    expect(gate.shouldHardReconnect, isFalse);
  });

  test('join after close starts a new generation', () {
    final gate = TrtcReconnectGate();
    gate.onJoinStarted();
    final first = gate.generation;
    gate.onClosed();
    gate.onJoinStarted();
    expect(gate.generation, isNot(first));
    expect(gate.phase, TrtcConnectionPhase.signaling);
  });
}
