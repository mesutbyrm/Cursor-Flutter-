import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_mobile/src/app.dart';

void main() {
  testWidgets('renders Canlifal app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CanlifalApp()));
    await tester.pump();

    expect(find.text('Canlifal'), findsOneWidget);
  });
}
