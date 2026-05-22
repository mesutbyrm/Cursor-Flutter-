import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_shell.dart';
import '../widgets/google_sign_in_button.dart';

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

  void _openGoogleOAuth() {
    context.push('/auth/google');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        ),
      );
    });

    return AuthShell(
      child: AuthFormCard(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrandHeader(
                title: 'Giriş Yap',
                subtitle: 'Hesabına giriş yap ve fal dünyasına dön.',
              ),
              const SizedBox(height: 24),
              if (Env.useNextAuth) ...[
                GoogleSignInButton(
                  label: 'Google ile devam et',
                  onPressed: _openGoogleOAuth,
                ),
                const SizedBox(height: 20),
                const AuthOrDivider(),
                const SizedBox(height: 20),
              ],
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
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: authInputDecoration(
                  labelText: 'Şifre',
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                ),
                validator: (v) =>
                    v != null && v.length >= 6 ? null : 'En az 6 karakter',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AuthTextLink(
                  label: 'Şifremi unuttum',
                  onPressed: () => context.push('/auth/forgot-password'),
                ),
              ),
              const SizedBox(height: 8),
              AuthPrimaryButton(
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
              const SizedBox(height: 4),
              AuthTextLink(
                label: 'Hesabın yok mu? Kayıt ol',
                onPressed: () => context.push('/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
