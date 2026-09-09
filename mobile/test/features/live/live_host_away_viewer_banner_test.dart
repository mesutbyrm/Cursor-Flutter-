import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_host_away_viewer_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows host away message for viewers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [LiveHostAwayViewerBanner(graceMinutes: 5)],
          ),
        ),
      ),
    );
    expect(find.textContaining('Yayıncının bağlantısı koptu'), findsOneWidget);
    expect(find.textContaining('5 dk'), findsOneWidget);
  });
}
