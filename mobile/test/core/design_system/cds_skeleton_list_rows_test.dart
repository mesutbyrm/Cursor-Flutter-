import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/design_system/cds_skeleton.dart';

void main() {
  for (final w in [320.0, 430.0]) {
    testWidgets('listRows $w px genişlikte taşma yok', (tester) async {
      tester.view.physicalSize = Size(w, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: CdsSkeleton.listRows())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Yükleniyor'), findsOneWidget);
    });
  }
}
