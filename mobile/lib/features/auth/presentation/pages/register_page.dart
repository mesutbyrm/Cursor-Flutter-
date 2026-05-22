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
  final _password2 = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    _name.dispose();
    _phone.dispose();
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
      useAppIcon: true,
      child: AuthFormCard(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrandHeader(
                title: 'Kayıt Ol',
                subtitle: 'Ücretsiz hesap oluştur; jeton ve fal dünyasına katıl.',
              ),
              if (nextAuth) ...[
                const SizedBox(height: 16),
                const AuthInfoBanner(
                  text:
                      'E-posta ile kayıt için web sitemizi kullanabilir veya Google ile '
                      'hemen bu uygulamadan devam edebilirsiniz.',
                ),
              ],
              const SizedBox(height: 20),
              if (nextAuth) ...[
                GoogleSignInButton(
                  label: 'Google ile kayıt ol / giriş yap',
                  onPressed: _openGoogleOAuth,
                ),
                const SizedBox(height: 18),
                const AuthOrDivider(),
                const SizedBox(height: 18),
              ],
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: authInputDecoration(
                  labelText: 'Ad Soyad',
                  hintText: 'Adınız Soyadınız',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                validator: (v) {
                  if (nextAuth) return null;
                  if (v == null || v.trim().length < 2) {
                    return 'Ad soyad girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: authInputDecoration(
                  labelText: 'Telefon (isteğe bağlı)',
                  hintText: '05xx xxx xx xx',
                  prefixIcon: Icons.phone_android_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: authInputDecoration(
                  labelText: 'E-posta',
                  hintText: 'ornek@email.com',
                  prefixIcon: Icons.mail_outline_rounded,
                ),
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Geçerli e-posta girin',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: authInputDecoration(
                  labelText: 'Şifre',
                  hintText: 'En az 6 karakter',
                  prefixIcon: Icons.lock_outline_rounded,
                ),
                validator: (v) =>
                    v != null && v.length >= 6 ? null : 'En az 6 karakter',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password2,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: authInputDecoration(
                  labelText: 'Şifre tekrar',
                  hintText: 'Şifrenizi tekrar girin',
                  prefixIcon: Icons.lock_reset_rounded,
                ),
                validator: (v) {
                  if (v != _password.text) return 'Şifreler eşleşmiyor';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: nextAuth ? 'Web sitesinde kayıt ol' : 'Kayıt Ol',
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
                              displayName: _name.text.trim(),
                            );
                      },
              ),
              AuthTextLink(
                label: 'Zaten hesabım var — Giriş yap',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
