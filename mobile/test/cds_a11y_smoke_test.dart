import 'package:canlifal_social/features/auth/presentation/widgets/premium_auth_2026/auth_neon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthNeonButton exposes button semantics label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthNeonButton(
            label: 'Giriş Yap',
            onPressed: () {},
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.text('Giriş Yap'));
    expect(semantics.label, 'Giriş Yap');
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
  });
}
