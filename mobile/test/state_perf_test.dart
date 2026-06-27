import 'package:canlifal_social/core/performance/state_perf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _counterProvider = StateProvider((ref) => 0);

void main() {
  testWidgets('SelectiveConsumer rebuilds only selected slice', (tester) async {
    var buildCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SelectiveConsumer<int>(
              provider: _counterProvider,
              select: (value) => value % 2,
              builder: (context, ref, parity) {
                buildCount++;
                return Text('parity $parity');
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('parity 0'), findsOneWidget);
    final initialBuilds = buildCount;

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SelectiveConsumer<int>)),
    );
    container.read(_counterProvider.notifier).state = 2;
    await tester.pump();

    expect(buildCount, initialBuilds);

    container.read(_counterProvider.notifier).state = 1;
    await tester.pump();

    expect(buildCount, greaterThan(initialBuilds));
    expect(find.text('parity 1'), findsOneWidget);
  });
}
