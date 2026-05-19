import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_links.dart';
import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../providers/auth_providers.dart';
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
    context.push(
      CanlifalWebRoute.location(
        relativePath: ApiEndpoints.authSignInGoogle,
        title: 'Google ile kayıt / giriş',
        sessionImport: true,
      ),
    );
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Kayıt ol'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    const Color(0xFF101828),
                    AppTheme.background,
                    const Color(0xFF1A0A14),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentSecondary.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentSecondary.withValues(alpha: 0.2),
                      blurRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Form(
                key: _form,
                child: ListView(
                  children: [
                    const SizedBox(height: 72),
                    Text(
                      'Topluluğa katıl',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Canlı yayınlar, sesli odalar ve coin ödülleri.',
                      style: TextStyle(
                        color: AppTheme.muted.withValues(alpha: 0.95),
                        height: 1.4,
                        fontSize: 15,
                      ),
                    ),
                    if (nextAuth) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppTheme.surface.withValues(alpha: 0.65),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          'E-posta ile kayıt için web sitemizi kullanabilir veya Google ile '
                          'hemen bu uygulamadan devam edebilirsiniz.',
                          style: TextStyle(
                            color: AppTheme.muted.withValues(alpha: 0.98),
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
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
                      decoration: const InputDecoration(
                        labelText: 'Görünen ad (isteğe bağlı)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) =>
                          v != null && v.contains('@')
                              ? null
                              : 'Geçerli e-posta girin',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (v) =>
                          v != null && v.length >= 6
                              ? null
                              : 'En az 6 karakter',
                    ),
                    const SizedBox(height: 26),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              nextAuth
                                  ? 'Web sitesinde kayıt ol'
                                  : 'Hesap oluştur',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(AppLinks.androidTestApk);
                        if (!await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bağlantı açılamadı'),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: AppTheme.muted.withValues(alpha: 0.9),
                      ),
                      label: Text(
                        'Android test APK indir',
                        style: TextStyle(
                          color: AppTheme.muted.withValues(alpha: 0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                      child: SelectableText(
                        AppLinks.androidTestApk,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: AppTheme.muted.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Zaten hesabım var'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
