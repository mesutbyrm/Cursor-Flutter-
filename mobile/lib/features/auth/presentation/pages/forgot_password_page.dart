import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../providers/auth_providers.dart';
import '../widgets/premium_auth_2026/premium_auth_2026.dart';

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
    return AuthPremiumShell(
      showBack: true,
      onBack: () => context.pop(),
      topTitle: 'Şifreni sıfırla',
      topSubtitle: 'E-postana güvenli bir sıfırlama bağlantısı göndereceğiz.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFloatingField(
              controller: _email,
              label: 'E-posta',
              hint: 'ornek@email.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Geçerli e-posta girin',
            ),
            const SizedBox(height: 22),
            AuthNeonButton(
              label: _loading ? 'Gönderiliyor…' : 'Bağlantı gönder',
              loading: _loading,
              onPressed: _loading ? null : _continue,
            ),
            AuthTextLinkPremium(
              label: 'Girişe dön',
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
