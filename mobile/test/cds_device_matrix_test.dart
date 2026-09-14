import 'package:canlifal_social/core/design_system/cds_responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dar ekran / landscape — overflow smoke (widget ağacı).
void main() {
  const widths = [360.0, 375.0, 390.0, 412.0, 480.0];

  testWidgets('CdsResponsive section height clamps on narrow widths',
      (tester) async {
    for (final w in widths) {
      await tester.binding.setSurfaceSize(Size(w, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final h = CdsResponsive.sectionHeight(
                context,
                min: 100,
                max: 210,
                fractionOfWidth: 0.55,
              );
              expect(h, greaterThanOrEqualTo(100));
              expect(h, lessThanOrEqualTo(210));
              return const SizedBox();
            },
          ),
        ),
      );
    }
  });

  testWidgets('Landscape row with ellipsis does not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              const Expanded(
                child: Text(
                  'Canlifal test metni uzun başlık overflow kontrolü',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
