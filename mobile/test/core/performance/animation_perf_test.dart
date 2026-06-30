import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/performance/animation_perf.dart';

class _TestDelegate extends CustomPainter with PaintLayerDelegate {
  _TestDelegate(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(color, BlendMode.src);
  }
}

void main() {
  test('PaintLayerDelegate accepts any CustomPainter as oldDelegate', () {
    final painter = _TestDelegate(Colors.red);
    expect(painter.shouldRepaint(_TestDelegate(Colors.blue)), isTrue);
    expect(
      painter.shouldRepaint(
        _RepaintListenablePainterForTest(
          delegate: _TestDelegate(Colors.green),
        ),
      ),
      isTrue,
    );
  });
}

/// Test-only — animation_perf private sınıfını taklit eder.
class _RepaintListenablePainterForTest extends CustomPainter {
  _RepaintListenablePainterForTest({required this.delegate});

  final CustomPainter delegate;

  @override
  void paint(Canvas canvas, Size size) => delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
