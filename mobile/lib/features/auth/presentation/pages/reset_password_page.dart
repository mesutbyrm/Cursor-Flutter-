import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../auth_navigation.dart';
import '../providers/auth_providers.dart';
import '../widgets/premium_auth_2026/premium_auth_2026.dart';

/// E-posta bağlantısındaki token ile şifre sıfırlama.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _form = GlobalKey<FormState>();
  var _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _loading) return;
    final token = widget.token?.trim() ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçersiz veya eksik sıfırlama bağlantısı.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            token: token,
            password: _password.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreniz güncellendi. Giriş yapabilirsiniz.')),
      );
      AuthNavigation.toLogin(context);
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
    final hasToken = (widget.token?.trim().isNotEmpty ?? false);

    return AuthPremiumShell(
      showBack: true,
      onBack: () => AuthNavigation.toLogin(context),
      topTitle: 'Yeni şifre',
      topSubtitle: hasToken
          ? 'Hesabın için güçlü bir şifre belirle.'
          : 'Bağlantı geçersiz; e-postanızdaki linki tekrar açın veya şifremi unuttum kullanın.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFloatingField(
              controller: _password,
              label: 'Yeni şifre',
              hint: 'En az 8 karakter',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (v) =>
                  v != null && v.length >= 8 ? null : 'En az 8 karakter',
            ),
            const SizedBox(height: 14),
            AuthFloatingField(
              controller: _password2,
              label: 'Şifre tekrar',
              prefixIcon: Icons.lock_reset_rounded,
              obscureText: true,
              validator: (v) =>
                  v == _password.text ? null : 'Şifreler eşleşmiyor',
            ),
            const SizedBox(height: 22),
            AuthNeonButton(
              label: 'Şifreyi güncelle',
              loading: _loading,
              onPressed: hasToken && !_loading ? _submit : null,
            ),
            AuthTextLinkPremium(
              label: 'Girişe dön',
              onPressed: () => AuthNavigation.toLogin(context),
            ),
          ],
        ),
      ),
    );
  }
}
