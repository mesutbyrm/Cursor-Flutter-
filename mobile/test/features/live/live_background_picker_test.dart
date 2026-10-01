import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/presentation/widgets/live_tiktok/live_background_picker_sheet.dart';

void main() {
  test('hazır arka planların hepsinin asset dosyası var', () {
    for (final p in LiveBackgroundPickerSheet.presets) {
      expect(File(p.asset).existsSync(), isTrue, reason: p.asset);
    }
  });

  testWidgets('seçici hazır görselleri ve galeri düğmesini gösterir',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LiveBackgroundPickerSheet(
              selectedUrl: null,
              onSelectUrl: (_) {},
              onSelectFile: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Mistik gece'), findsOneWidget);
    expect(find.text('Galeriden seç'), findsOneWidget);
  });
}
