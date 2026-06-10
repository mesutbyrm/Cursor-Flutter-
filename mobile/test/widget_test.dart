import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Material uygulama iskeleti açılır', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Canlifal'))),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Canlifal'), findsOneWidget);
  });
}
