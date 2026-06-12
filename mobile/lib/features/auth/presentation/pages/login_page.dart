import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/bootstrap/app_startup_log.dart';
import '../../../../core/bootstrap/stuck_overlay_guard.dart';
import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../auth_navigation.dart';
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
  Timer? _overlayScrubTimer;
  var _overlayScrubTicks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearStuckOverlays('mount');
      _armOverlayScrub();
    });
  }

  void _armOverlayScrub() {
    _overlayScrubTimer?.cancel();
    _overlayScrubTicks = 0;
    _overlayScrubTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _overlayScrubTicks >= 40) {
        _overlayScrubTimer?.cancel();
        return;
      }
      _overlayScrubTicks++;
      _clearStuckOverlays('scrub-$_overlayScrubTicks');
    });
  }

  void _clearStuckOverlays(String reason) {
    if (!mounted) return;
    AppStartupLog.log('LoginPage overlay clear ($reason)');
    StuckOverlayGuard.dismissRoot(reason: 'login-$reason');
  }

  @override
  void dispose() {
    _overlayScrubTimer?.cancel();
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
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final formBusy = ref.watch(authUserActionBusyProvider);
    final sessionChecking = auth.isLoading && !auth.hasValue;

    ref.listen(authControllerProvider, (prev, next) {
      final wasLoading = prev?.isLoading ?? true;
      if (wasLoading && !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _clearStuckOverlays('auth-finish');
          _armOverlayScrub();
        });
      }
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
      topSubtitle: sessionChecking
          ? 'Oturum kontrol ediliyor…'
          : 'Sesli odalara katıl, fal dünyasını keşfet.',
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
                onPressed: () => AuthNavigation.toForgotPassword(context),
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
                            _email.text.trim(),
                            _password.text,
                          );
                    },
            ),
            const SizedBox(height: 6),
            AuthTextLinkPremium(
              label: 'Hesabın yok mu? Kayıt ol',
              onPressed: () => AuthNavigation.toRegister(context),
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
