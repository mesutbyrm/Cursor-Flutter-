import 'package:canlifal_social/features/auth/presentation/widgets/premium_auth_2026/auth_plain_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('arka plan görseli ekranı kaplar ve klavye açılınca ölçeği değişmez',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: AuthPlainShell(child: TextField(key: Key('f'))),
      ),
    );
    await tester.pump();

    // cacheWidth verildiği için sağlayıcı ResizeImage ile sarılır.
    bool isNightSky(ImageProvider p) {
      final inner = p is ResizeImage ? p.imageProvider : p;
      return inner is AssetImage && inner.assetName.contains('login-night-sky');
    }

    final bg = find.byWidgetPredicate((w) => w is Image && isNightSky(w.image));
    expect(bg, findsOneWidget);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getSize(bg), screen);
    expect((tester.widget(bg) as Image).fit, BoxFit.cover);

    // Klavye (300 dp) açılır.
    tester.view.viewInsets = const FakeViewPadding(bottom: 900); // 300 dp
    await tester.pump();
    expect(tester.getSize(bg), screen, reason: 'görsel yeniden ölçeklenmemeli');
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).resizeToAvoidBottomInset, isFalse);
    expect(tester.takeException(), isNull);
  });
}
