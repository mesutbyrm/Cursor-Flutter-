import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/premium_fortune/presentation/home/pf_home_page.dart';

void main() {
  testWidgets('PfHomePage renders module cards', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PfHomePage(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Mistik Yolculuğunuz'), findsOneWidget);
    expect(find.text('Kahve Falı'), findsOneWidget);
    expect(find.text('Tarot'), findsOneWidget);
    expect(find.text('Canlı Falcı'), findsOneWidget);
  });
}
