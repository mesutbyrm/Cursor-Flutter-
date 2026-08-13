import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/home/presentation/widgets/home_viewport_section.dart';

void main() {
  testWidgets('HomeViewportSection mounts child after scroll near viewport',
      (tester) async {
    final controller = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            controller: controller,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 2000)),
              SliverToBoxAdapter(
                child: HomeViewportSection(
                  estimatedHeight: 80,
                  child: const Text('lazy-content'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('lazy-content'), findsNothing);

    controller.jumpTo(1900);
    await tester.pumpAndSettle();

    expect(find.text('lazy-content'), findsOneWidget);
  });
}
