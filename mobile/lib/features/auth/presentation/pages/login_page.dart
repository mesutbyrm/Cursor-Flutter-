import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../auth_navigation.dart';
import '../providers/auth_providers.dart';
import '../widgets/premium_auth_2026/premium_auth_2026.dart';

/// Giriş — tam ekran loading dialog yok; [authUserActionBusyProvider] ile buton
/// içi spinner. Başarılı oturumda yalnızca go_router redirect `/feed` (manuel
/// context.go/push yok — çift navigasyon ve yetim barrier önlenir).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifier.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final formBusy = ref.watch(authUserActionBusyProvider);
    final sessionChecking = auth.isLoading && !auth.hasValue;

    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        ),
      );
    });

    return AuthPremiumShell(
      heroLogo: true,
      topTitle: 'Hoş geldin',
      topSubtitle: sessionChecking
          ? 'Oturum kontrol ediliyor…'
          : 'Google ile hızlı giriş veya e-posta ile devam edin.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sessionChecking)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Color(0x22FFFFFF),
                  color: Color(0xFF9B4DFF),
                ),
              ),
            AuthSocialSection(
              busy: formBusy,
              googleLabel: 'Google ile Giriş yap',
              onGoogle: formBusy
                  ? null
                  : () => ref
                      .read(authControllerProvider.notifier)
                      .loginWithGoogle(),
              onTikTok: formBusy
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
              controller: _identifier,
              label: 'E-posta veya kullanıcı adı',
              hint: 'ornek@email.com veya kullanici_adi',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.text,
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              validator: (v) =>
                  v != null && v.trim().length >= 3 ? null : 'En az 3 karakter',
            ),
            const SizedBox(height: 14),
            AuthFloatingField(
              controller: _password,
              label: 'Şifre',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (v) =>
                  v != null && v.length >= 6 ? null : 'En az 6 karakter',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AuthTextLinkPremium(
                label: 'Şifremi unuttum',
                onPressed: () {
                  if (formBusy) return;
                  AuthNavigation.toForgotPassword(context);
                },
              ),
            ),
            const SizedBox(height: 8),
            AuthNeonButton(
              label: 'Giriş Yap',
              loading: formBusy,
              onPressed: formBusy
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      await ref.read(authControllerProvider.notifier).login(
                            _identifier.text.trim(),
                            _password.text,
                          );
                      _password.clear();
                    },
            ),
            const SizedBox(height: 6),
            AuthTextLinkPremium(
              label: 'Hesabın yok mu? Kayıt ol',
              onPressed: () {
                if (formBusy) return;
                AuthNavigation.toRegister(context);
              },
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
