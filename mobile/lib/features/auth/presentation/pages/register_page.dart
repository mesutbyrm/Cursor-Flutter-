import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Kayıt ol'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _form,
            child: ListView(
              children: [
                const SizedBox(height: 24),
                Text(
                  'Topluluğa katıl',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Canlı yayınlar, mesajlar ve coin ödülleri seni bekliyor.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                if (nextAuth) ...[
                  const SizedBox(height: 20),
                  Material(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Hesap oluşturmak için canlifal.com sitesini kullanın; '
                        'giriş yaptıktan sonra bu uygulamadan devam edebilirsiniz.',
                        style: TextStyle(color: AppTheme.muted, height: 1.35),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Görünen ad (isteğe bağlı)',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : 'Geçerli e-posta girin',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : 'En az 6 karakter',
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          if (nextAuth) {
                            await _openWebRegister();
                            return;
                          }
                          if (!_form.currentState!.validate()) return;
                          await ref
                              .read(authControllerProvider.notifier)
                              .register(
                                _email.text.trim(),
                                _password.text,
                                displayName: _name.text.trim().isEmpty
                                    ? null
                                    : _name.text.trim(),
                              );
                        },
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(nextAuth ? 'Web sitesinde kayıt ol' : 'Hesap oluştur'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Zaten hesabım var'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
