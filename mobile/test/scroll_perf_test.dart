import 'package:canlifal_social/core/performance/scroll_perf.dart';
import 'package:canlifal_social/core/widgets/lazy_list_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cacheFor returns surface-specific extents', () {
    expect(ScrollPerf.cacheFor(ScrollSurface.feed), 560);
    expect(ScrollPerf.cacheFor(ScrollSurface.chat), 320);
    expect(ScrollPerf.cacheFor(ScrollSurface.grid), 400);
  });

  testWidgets('LazyListView builds only visible rows', (tester) async {
    var built = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 120,
            child: LazyListView(
              itemCount: 40,
              itemBuilder: (_, __) {
                built++;
                return const SizedBox(height: 48, child: ColoredBox(color: Colors.blue));
              },
            ),
          ),
        ),
      ),
    );
    expect(built, lessThan(40));
    expect(find.byType(LazyListView), findsOneWidget);
  });

  testWidgets('LazyNestedGridView disables nested scroll', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LazyNestedGridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 40,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => const ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      ),
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
    expect(grid.shrinkWrap, isFalse);
  });
}
