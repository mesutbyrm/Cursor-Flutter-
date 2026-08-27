import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/trtc/presentation/trtc_operation_gate.dart';

void main() {
  test('TrtcOperationGate serializes overlapping join/leave', () async {
    final gate = TrtcOperationGate();
    final order = <int>[];
    final first = gate.run(() async {
      order.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      order.add(2);
    });
    final second = gate.run(() async {
      order.add(3);
    });
    await Future.wait([first, second]);
    expect(order, [1, 2, 3]);
    expect(gate.isBusy, isFalse);
  });

  test('TrtcOperationGate reports in-flight while queued', () {
    final gate = TrtcOperationGate();
    gate.run(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    expect(gate.isBusy, isTrue);
  });
}
