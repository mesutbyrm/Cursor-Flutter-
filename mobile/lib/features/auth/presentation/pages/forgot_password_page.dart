import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../widgets/auth_shell.dart';

/// Şifre sıfırlama — e-posta ile OTP akışına yönlendirir.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_form.currentState!.validate()) return;
    final email = _email.text.trim();
    if (Env.useNextAuth) {
      context.push(
        CanlifalWebRoute.location(
          relativePath: '/auth/forgot-password?email=${Uri.encodeComponent(email)}',
          title: 'Şifre sıfırla',
        ),
      );
      return;
    }
    context.push('/auth/otp-verify', extra: email);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      child: AuthFormCard(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrandHeader(
                title: 'Şifreni sıfırla',
                subtitle: 'E-postana doğrulama kodu göndereceğiz.',
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: 'Kod gönder',
                onPressed: _continue,
              ),
              AuthTextLink(
                label: 'Girişe dön',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
