import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/core/ui/premium/premium_bottom_sheet.dart';

Future<void> _open(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              showPremiumBottomSheet<void>(context: context, child: child),
          child: const Text('aç'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('aç'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'DraggableScrollableSheet içeren alt sayfa düzen hatası vermeden açılır',
    (tester) async {
      await _open(
        tester,
        DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          builder: (_, scroll) => ListView(
            controller: scroll,
            children: const [Text('içerik')],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('içerik'), findsOneWidget);
    },
  );

  testWidgets('kısa içerik kendi yüksekliğinde kalır', (tester) async {
    await _open(
      tester,
      const SizedBox(key: Key('kisa'), height: 120, child: Text('kısa')),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const Key('kisa'))).height, 120);
  });
}
