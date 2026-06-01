import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../providers/auth_providers.dart';
import '../widgets/premium_auth_2026/premium_auth_2026.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _soon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label yakında aktif olacak.')),
    );
  }

  void _continueAsGuest() {
    ref.read(guestModeProvider.notifier).state = true;
    context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            ref.read(guestModeProvider.notifier).state = false;
          }
        },
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        ),
      );
    });

    return AuthPremiumShell(
      heroLogo: true,
      topTitle: 'Hoş geldin',
      topSubtitle: 'Sesli odalara katıl, fal dünyasını keşfet.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthSocialSection(
              busy: auth.isLoading,
              googleLabel: 'Google ile Giriş yap',
              onGoogle: auth.isLoading
                  ? null
                  : () => ref
                      .read(authControllerProvider.notifier)
                      .loginWithGoogle(),
              onTikTok: auth.isLoading
                  ? null
                  : () => ref
                      .read(authControllerProvider.notifier)
                      .loginWithTikTok(),
              onApple: () => _soon('Apple girişi'),
              onGuest: _continueAsGuest,
            ),
            const SizedBox(height: 22),
            const AuthOrDividerPremium(),
            const SizedBox(height: 22),
            AuthFloatingField(
              controller: _email,
              label: 'E-posta',
              hint: 'ornek@email.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Geçerli e-posta girin',
            ),
            const SizedBox(height: 14),
            AuthFloatingField(
              controller: _password,
              label: 'Şifre',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              validator: (v) =>
                  v != null && v.length >= 6 ? null : 'En az 6 karakter',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AuthTextLinkPremium(
                label: 'Şifremi unuttum',
                onPressed: () => context.push('/auth/forgot-password'),
              ),
            ),
            const SizedBox(height: 8),
            AuthNeonButton(
              label: 'Giriş Yap',
              loading: auth.isLoading,
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      await ref.read(authControllerProvider.notifier).login(
                            _email.text.trim(),
                            _password.text,
                          );
                    },
            ),
            const SizedBox(height: 6),
            AuthTextLinkPremium(
              label: 'Hesabın yok mu? Kayıt ol',
              onPressed: () => context.push('/register'),
            ),
            if (!Env.hasTikTokLogin) ...[
              const SizedBox(height: 4),
              Text(
                'TikTok girişi yapılandırıldığında burada görünür.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
