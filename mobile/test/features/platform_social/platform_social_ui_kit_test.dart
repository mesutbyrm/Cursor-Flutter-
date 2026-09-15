import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/platform_social/presentation/widgets/platform_social_ui_kit.dart';

void main() {
  testWidgets('PlatformSocialGlassCard renders title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlatformSocialGlassCard(
            child: Text('Arena'),
          ),
        ),
      ),
    );
    expect(find.text('Arena'), findsOneWidget);
  });
}
