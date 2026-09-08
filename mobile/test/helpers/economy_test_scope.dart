import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/economy/domain/currency_branding_snapshot.dart';
import 'package:canlifal_social/core/economy/presentation/providers/economy_providers.dart';

/// Widget testlerinde `economyCurrencyLabel` — varsayılan Jeton/CFC markası.
Widget wrapEconomyScope(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      currencyBrandingProvider.overrideWith(
        (ref) async => CurrencyBrandingSnapshot.defaults,
      ),
      ...overrides,
    ],
    child: child,
  );
}

Future<void> pumpEconomyWidget(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Size surfaceSize = const Size(480, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(wrapEconomyScope(child, overrides: overrides));
  await tester.pumpAndSettle();
}
