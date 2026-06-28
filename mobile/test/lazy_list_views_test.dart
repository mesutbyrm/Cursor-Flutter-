import 'package:canlifal_social/core/widgets/lazy_list_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LazyListView builds only visible children', (tester) async {
    var built = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LazyListView(
            itemCount: 100,
            itemBuilder: (context, index) {
              built++;
              return SizedBox(height: 48, child: Text('item $index'));
            },
          ),
        ),
      ),
    );

    expect(built, lessThan(100));
    expect(find.byType(LazyListView), findsOneWidget);
  });

  testWidgets('LazyHorizontalListView uses horizontal ListView.builder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LazyHorizontalListView(
            itemCount: 5,
            itemBuilder: (context, index) => SizedBox(
              width: 80,
              child: Text('chip $index'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('chip 0'), findsOneWidget);
  });
}
