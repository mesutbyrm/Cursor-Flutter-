import 'package:canlifal_social/features/auth/presentation/pages/otp_verify_page.dart';
import 'package:canlifal_social/features/auth/presentation/pages/register_page.dart';
import 'package:canlifal_social/features/auth/presentation/widgets/premium_auth_2026/auth_neon_button.dart';
import 'package:canlifal_social/features/messages/presentation/widgets/chat_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthNeonButton(
            label: 'Giriş Yap',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Giriş Yap'));
    expect(tapped, isTrue);
  });

  testWidgets('Register page exposes Kayıt ol button semantics', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RegisterPage()),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Kayıt ol'), findsOneWidget);
    expect(find.bySemanticsLabel('Adınız'), findsWidgets);
  });

  testWidgets('OTP page exposes digit field semantics', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OtpVerifyPage(email: 'test@example.com'),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.bySemanticsLabel('Doğrulama kodu 1 / 6'), findsOneWidget);
    expect(find.bySemanticsLabel('Doğrulama kodu 6 / 6'), findsOneWidget);
  });

  testWidgets('ChatComposer exposes message field and send', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ChatComposer(
              controller: controller,
              onSend: () {},
              sending: false,
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Mesaj gönder'), findsOneWidget);
    expect(find.bySemanticsLabel('Ek ekle'), findsOneWidget);
    final fieldSemantics = tester.getSemantics(find.byType(TextField));
    expect(fieldSemantics.label, 'Mesaj yazın');
  });
}
