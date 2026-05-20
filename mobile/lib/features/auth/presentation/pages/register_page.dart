import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_shell.dart';
import '../widgets/google_sign_in_button.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _openWebRegister() async {
    final uri = Uri.parse('${Env.siteOrigin}/kayit');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarayıcı açılamadı')),
      );
    }
  }

  void _openGoogleOAuth() {
    context.push('/auth/google');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final nextAuth = Env.useNextAuth;
    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        ),
      );
    });

    return AuthShell(
      showBack: true,
      onBack: () => context.pop(),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthSectionTitle(
              title: 'Topluluğa katıl',
              subtitle: 'Canlı yayınlar, sesli odalar ve coin ödülleri.',
            ),
            if (nextAuth) ...[
              const SizedBox(height: 18),
              const AuthInfoBanner(
                text:
                    'E-posta ile kayıt için web sitemizi kullanabilir veya Google ile '
                    'hemen bu uygulamadan devam edebilirsiniz.',
              ),
            ],
            const SizedBox(height: 24),
            if (nextAuth) ...[
              GoogleSignInButton(
                label: 'Google ile kayıt ol / giriş yap',
                onPressed: _openGoogleOAuth,
              ),
              const SizedBox(height: 20),
              const AuthOrDivider(),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: _name,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: authInputDecoration(
                labelText: 'Görünen ad (isteğe bağlı)',
                prefixIcon: Icons.badge_outlined,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: authInputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icons.mail_outline_rounded,
              ),
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Geçerli e-posta girin',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: authInputDecoration(
                labelText: 'Şifre',
                prefixIcon: Icons.lock_outline_rounded,
              ),
              validator: (v) =>
                  v != null && v.length >= 6 ? null : 'En az 6 karakter',
            ),
            const SizedBox(height: 26),
            AuthPrimaryButton(
              label: nextAuth ? 'Web sitesinde kayıt ol' : 'Hesap oluştur',
              loading: auth.isLoading,
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      if (nextAuth) {
                        await _openWebRegister();
                        return;
                      }
                      if (!_form.currentState!.validate()) return;
                      await ref.read(authControllerProvider.notifier).register(
                            _email.text.trim(),
                            _password.text,
                            displayName: _name.text.trim().isEmpty
                                ? null
                                : _name.text.trim(),
                          );
                    },
            ),
            AuthTextLink(
              label: 'Zaten hesabım var',
              onPressed: () => context.pop(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
