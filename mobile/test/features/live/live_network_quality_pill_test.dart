import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_network_quality_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows İyi for TRTC quality 1', (tester) async {
    final quality = ValueNotifier<int?>(1);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveNetworkQualityPill(qualityListenable: quality),
        ),
      ),
    );
    expect(find.text('İyi'), findsOneWidget);
    expect(find.text('🟢'), findsOneWidget);
  });

  testWidgets('shows Orta for TRTC quality 2', (tester) async {
    final quality = ValueNotifier<int?>(2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveNetworkQualityPill(qualityListenable: quality),
        ),
      ),
    );
    expect(find.text('Orta'), findsOneWidget);
    expect(find.text('🟡'), findsOneWidget);
  });

  testWidgets('shows Zayıf for poor quality', (tester) async {
    final quality = ValueNotifier<int?>(5);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveNetworkQualityPill(qualityListenable: quality),
        ),
      ),
    );
    expect(find.text('Zayıf'), findsOneWidget);
    expect(find.text('🔴'), findsOneWidget);
  });

  testWidgets('shows Bağlanıyor when quality is null', (tester) async {
    final quality = ValueNotifier<int?>(null);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveNetworkQualityPill(qualityListenable: quality),
        ),
      ),
    );
    expect(find.text('Bağlanıyor'), findsOneWidget);
  });
}
