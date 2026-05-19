import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/app/app.dart';

void main() {
  testWidgets('Uygulama açılır', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CanlifalApp()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
