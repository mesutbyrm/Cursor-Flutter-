import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_shell.dart';

/// Şifre sıfırlama — canlifal.com native API (e-posta bağlantısı).
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  var _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_form.currentState!.validate() || _loading) return;
    final email = _email.text.trim();

    if (!Env.useMobileAuth) {
      context.push('/auth/otp-verify', extra: email);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Şifre sıfırlama bağlantısı e-postanıza gönderildi. '
            'Gelen kutunuzu ve spam klasörünü kontrol edin.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                subtitle:
                    'E-postana güvenli bir sıfırlama bağlantısı göndereceğiz.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: context.colors.onSurface),
                decoration: authInputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icons.mail_outline_rounded,
                ),
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Geçerli e-posta girin',
              ),
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: _loading ? 'Gönderiliyor…' : 'Bağlantı gönder',
                onPressed: _loading ? null : _continue,
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
