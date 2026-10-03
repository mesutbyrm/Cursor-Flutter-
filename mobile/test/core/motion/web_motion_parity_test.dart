import 'package:canlifal_social/core/motion/canlifal_motion_tokens.dart';
import 'package:canlifal_social/core/motion/canlifal_motion_widgets.dart';
import 'package:canlifal_social/core/navigation/app_page_transitions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web sabitleri: 0.3 sn, y 20, stagger 50 ms, modal 0.9', () {
    expect(CanlifalMotionTokens.webEnter, const Duration(milliseconds: 300));
    expect(CanlifalMotionTokens.webRisePx, 20);
    expect(CanlifalMotionTokens.webStagger, const Duration(milliseconds: 50));
    expect(CanlifalMotionTokens.webModalScale, 0.9);
  });

  testWidgets('webRiseOffset ekran yüksekliğine göre 20 px eder', (t) async {
    late Offset o;
    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: Builder(
          builder: (c) {
            o = webRiseOffset(c);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(o.dy * 800, closeTo(20, 0.001));
  });

  test('staggered gecikme 50 ms × index, en çok 5', () {
    final w = CanlifalEntranceFadeSlide.staggered(
      index: 9,
      child: const SizedBox(),
    );
    expect(w.delay, const Duration(milliseconds: 250));
    expect(
      CanlifalEntranceFadeSlide.staggered(index: 2, child: const SizedBox()).delay,
      const Duration(milliseconds: 100),
    );
  });
}
