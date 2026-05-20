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
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBrandHeader(title: 'Hesabına giriş yap'),
            const SizedBox(height: 28),
            if (Env.useNextAuth) ...[
              GoogleSignInButton(
                label: 'Google ile devam et',
                onPressed: _openGoogleOAuth,
              ),
              const SizedBox(height: 22),
              const AuthOrDivider(),
              const SizedBox(height: 22),
            ],
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
              label: 'Giriş yap',
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
            AuthTextLink(
              label: 'Hesabın yok mu? Kayıt ol',
              onPressed: () => context.push('/register'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
